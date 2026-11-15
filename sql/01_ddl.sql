-- =====================================================================
--  db_ensalamento - FASE 3: MODELO FÍSICO (DDL) - PostgreSQL
--  Sistema de Ensalamento Acadêmico - FATESE
-- ---------------------------------------------------------------------
--  Como rodar:
--    1) Crie o banco (uma vez):   CREATE DATABASE db_ensalamento;
--    2) Conecte-se a ele no pgAdmin (Query Tool) e execute este arquivo.
--  O script é reexecutável: apaga e recria todos os objetos.
-- =====================================================================

-- Extensão nativa do PostgreSQL que permite combinar "=" com
-- sobreposição de intervalos (&&) numa mesma restrição EXCLUDE.
-- É ela que barra os CHOQUES DE HORÁRIO direto no banco.
CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS alocacao      CASCADE;
DROP TABLE IF EXISTS turma         CASCADE;
DROP TABLE IF EXISTS turno         CASCADE;
DROP TABLE IF EXISTS disciplina    CASCADE;
DROP TABLE IF EXISTS laboratorio   CASCADE;
DROP TABLE IF EXISTS sala          CASCADE;
DROP TABLE IF EXISTS espaco_fisico CASCADE;
DROP TABLE IF EXISTS professor     CASCADE;
DROP FUNCTION IF EXISTS fn_valida_alocacao() CASCADE;
DROP TYPE IF EXISTS faixa_horaria CASCADE;

-- Tipo de intervalo de horários (ex.: [08:00, 12:00) ).
-- Fechado no início e aberto no fim: uma aula 08-10 NÃO conflita com 10-12.
CREATE TYPE faixa_horaria AS RANGE (subtype = time);

-- ---------------------------------------------------------------------
-- PROFESSOR
-- ---------------------------------------------------------------------
CREATE TABLE professor (
    id_professor  SERIAL        PRIMARY KEY,
    matricula     VARCHAR(10)   NOT NULL UNIQUE,
    nome          VARCHAR(100)  NOT NULL,
    email         VARCHAR(120)  NOT NULL UNIQUE,
    titulacao     VARCHAR(20)   NOT NULL,
    departamento  VARCHAR(60)   NOT NULL,
    CONSTRAINT ck_professor_titulacao
        CHECK (titulacao IN ('Graduado', 'Especialista', 'Mestre', 'Doutor')),
    CONSTRAINT ck_professor_email
        CHECK (email LIKE '%_@_%._%')
);

-- ---------------------------------------------------------------------
-- ESPAÇO FÍSICO (superclasse) + especializações SALA e LABORATÓRIO
-- A coluna tipo_espaco + a FK composta garantem que um espaço
-- do tipo 'LABORATORIO' nunca seja cadastrado como 'SALA' (e vice-versa).
-- ---------------------------------------------------------------------
CREATE TABLE espaco_fisico (
    id_espaco     SERIAL       PRIMARY KEY,
    codigo        VARCHAR(30)  NOT NULL UNIQUE,      -- ex.: 'Sala 101', 'Lab 2'
    bloco         VARCHAR(10)  NOT NULL,
    capacidade    SMALLINT     NOT NULL,
    tipo_espaco   VARCHAR(11)  NOT NULL,
    CONSTRAINT ck_espaco_capacidade CHECK (capacidade > 0),
    CONSTRAINT ck_espaco_tipo       CHECK (tipo_espaco IN ('SALA', 'LABORATORIO')),
    CONSTRAINT uq_espaco_id_tipo    UNIQUE (id_espaco, tipo_espaco)
);

CREATE TABLE sala (
    id_espaco        INTEGER     PRIMARY KEY,
    tipo_espaco      VARCHAR(11) NOT NULL DEFAULT 'SALA',
    possui_projetor  BOOLEAN     NOT NULL,
    CONSTRAINT ck_sala_tipo CHECK (tipo_espaco = 'SALA'),
    CONSTRAINT fk_sala_espaco FOREIGN KEY (id_espaco, tipo_espaco)
        REFERENCES espaco_fisico (id_espaco, tipo_espaco)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE laboratorio (
    id_espaco          INTEGER      PRIMARY KEY,
    tipo_espaco        VARCHAR(11)  NOT NULL DEFAULT 'LABORATORIO',
    qtd_computadores   SMALLINT     NOT NULL,
    tipo_equipamento   VARCHAR(80)  NOT NULL,
    CONSTRAINT ck_lab_tipo CHECK (tipo_espaco = 'LABORATORIO'),
    CONSTRAINT ck_lab_qtd_computadores CHECK (qtd_computadores >= 0),
    CONSTRAINT fk_lab_espaco FOREIGN KEY (id_espaco, tipo_espaco)
        REFERENCES espaco_fisico (id_espaco, tipo_espaco)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- DISCIPLINA
-- Regra: 40h -> 2h semanais | 80h -> 4h semanais (coluna calculada).
-- ---------------------------------------------------------------------
CREATE TABLE disciplina (
    id_disciplina   SERIAL       PRIMARY KEY,
    nome            VARCHAR(80)  NOT NULL UNIQUE,
    carga_horaria   SMALLINT     NOT NULL,
    horas_semanais  SMALLINT     GENERATED ALWAYS AS (carga_horaria / 20) STORED,
    CONSTRAINT ck_disciplina_carga CHECK (carga_horaria IN (40, 80))
);

-- ---------------------------------------------------------------------
-- TURNO (Matutino 08-12 | Vespertino 14-18 | Noturno 19-23)
-- ---------------------------------------------------------------------
CREATE TABLE turno (
    id_turno     SMALLINT     PRIMARY KEY,
    nome         VARCHAR(10)  NOT NULL UNIQUE,
    hora_inicio  TIME         NOT NULL,
    hora_fim     TIME         NOT NULL,
    CONSTRAINT ck_turno_nome    CHECK (nome IN ('Matutino', 'Vespertino', 'Noturno')),
    CONSTRAINT ck_turno_horario CHECK (hora_fim > hora_inicio)
);

-- ---------------------------------------------------------------------
-- TURMA
-- ---------------------------------------------------------------------
CREATE TABLE turma (
    id_turma    SERIAL        PRIMARY KEY,
    codigo      VARCHAR(10)   NOT NULL UNIQUE,      -- ex.: 'T1'
    nome        VARCHAR(80)   NOT NULL,             -- ex.: 'Engenharia de Software'
    qtd_alunos  SMALLINT      NOT NULL,
    id_turno    SMALLINT      NOT NULL,
    CONSTRAINT ck_turma_alunos CHECK (qtd_alunos > 0),
    CONSTRAINT fk_turma_turno FOREIGN KEY (id_turno)
        REFERENCES turno (id_turno) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- ALOCAÇÃO (tabela associativa: Turma x Disciplina x Professor x Espaço
--           em um dia da semana e faixa de horário)
-- ---------------------------------------------------------------------
CREATE TABLE alocacao (
    id_alocacao    SERIAL       PRIMARY KEY,
    id_turma       INTEGER      NOT NULL,
    id_disciplina  INTEGER      NOT NULL,
    id_professor   INTEGER      NOT NULL,
    id_espaco      INTEGER      NOT NULL,
    dia_semana     VARCHAR(7)   NOT NULL,
    hora_inicio    TIME         NOT NULL,
    hora_fim       TIME         NOT NULL,

    CONSTRAINT fk_aloc_turma      FOREIGN KEY (id_turma)
        REFERENCES turma (id_turma)           ON DELETE RESTRICT,
    CONSTRAINT fk_aloc_disciplina FOREIGN KEY (id_disciplina)
        REFERENCES disciplina (id_disciplina) ON DELETE RESTRICT,
    CONSTRAINT fk_aloc_professor  FOREIGN KEY (id_professor)
        REFERENCES professor (id_professor)   ON DELETE RESTRICT,
    CONSTRAINT fk_aloc_espaco     FOREIGN KEY (id_espaco)
        REFERENCES espaco_fisico (id_espaco)  ON DELETE RESTRICT,

    CONSTRAINT ck_aloc_dia CHECK (dia_semana IN
        ('Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado')),
    -- Horas diárias da aula entre 1 e 4 horas
    CONSTRAINT ck_aloc_duracao CHECK (
        hora_fim > hora_inicio
        AND (hora_fim - hora_inicio) BETWEEN INTERVAL '1 hour' AND INTERVAL '4 hours'),

    -- ===== FIM DOS CHOQUES DE HORÁRIO =====
    -- Mesmo professor não pode estar em duas aulas sobrepostas no mesmo dia
    CONSTRAINT ex_choque_professor EXCLUDE USING gist (
        id_professor WITH =, dia_semana WITH =,
        faixa_horaria(hora_inicio, hora_fim) WITH &&),
    -- Mesmo espaço físico não pode receber duas aulas sobrepostas
    CONSTRAINT ex_choque_espaco EXCLUDE USING gist (
        id_espaco WITH =, dia_semana WITH =,
        faixa_horaria(hora_inicio, hora_fim) WITH &&),
    -- Mesma turma não pode ter duas aulas sobrepostas
    CONSTRAINT ex_choque_turma EXCLUDE USING gist (
        id_turma WITH =, dia_semana WITH =,
        faixa_horaria(hora_inicio, hora_fim) WITH &&)
);

-- ---------------------------------------------------------------------
-- Regras que envolvem OUTRAS tabelas (CHECK não enxerga outras tabelas,
-- por isso usamos uma função de gatilho):
--   R1. Nº de alunos da turma <= capacidade do espaço físico
--   R2. Horário da aula dentro do turno da turma
--   R3. Total semanal da disciplina na turma <= horas_semanais (2h ou 4h)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_valida_alocacao()
RETURNS TRIGGER AS $$
DECLARE
    v_alunos      SMALLINT;
    v_capacidade  SMALLINT;
    v_codigo_esp  VARCHAR;
    v_turno       turno%ROWTYPE;
    v_limite      SMALLINT;
    v_alocado     INTERVAL;
BEGIN
    -- R1: capacidade
    SELECT t.qtd_alunos INTO v_alunos FROM turma t WHERE t.id_turma = NEW.id_turma;
    SELECT e.capacidade, e.codigo INTO v_capacidade, v_codigo_esp
      FROM espaco_fisico e WHERE e.id_espaco = NEW.id_espaco;
    IF v_alunos > v_capacidade THEN
        RAISE EXCEPTION 'Capacidade insuficiente: % comporta % alunos, mas a turma tem %.',
            v_codigo_esp, v_capacidade, v_alunos;
    END IF;

    -- R2: turno
    SELECT tn.* INTO v_turno
      FROM turma t JOIN turno tn ON tn.id_turno = t.id_turno
     WHERE t.id_turma = NEW.id_turma;
    IF NEW.hora_inicio < v_turno.hora_inicio OR NEW.hora_fim > v_turno.hora_fim THEN
        RAISE EXCEPTION 'Horário fora do turno: a turma é do turno % (% às %).',
            v_turno.nome, v_turno.hora_inicio, v_turno.hora_fim;
    END IF;

    -- R3: carga semanal da disciplina
    SELECT d.horas_semanais INTO v_limite
      FROM disciplina d WHERE d.id_disciplina = NEW.id_disciplina;
    SELECT COALESCE(SUM(a.hora_fim - a.hora_inicio), INTERVAL '0')
      INTO v_alocado
      FROM alocacao a
     WHERE a.id_turma = NEW.id_turma
       AND a.id_disciplina = NEW.id_disciplina
       AND a.id_alocacao IS DISTINCT FROM NEW.id_alocacao;
    IF v_alocado + (NEW.hora_fim - NEW.hora_inicio) > make_interval(hours => v_limite) THEN
        RAISE EXCEPTION 'Carga semanal excedida: a disciplina exige % h/semana para esta turma.',
            v_limite;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_valida_alocacao
BEFORE INSERT OR UPDATE ON alocacao
FOR EACH ROW EXECUTE FUNCTION fn_valida_alocacao();

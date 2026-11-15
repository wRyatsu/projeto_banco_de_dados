-- =====================================================================
--  db_ensalamento - FASE 4: POVOAMENTO (DML)
--  Rode DEPOIS de 01_ddl.sql (o DDL limpa o banco antes).
-- =====================================================================

-- ---------------------------------------------------------------------
-- TURNOS
-- ---------------------------------------------------------------------
INSERT INTO turno (id_turno, nome, hora_inicio, hora_fim) VALUES
    (1, 'Matutino',   '08:00', '12:00'),
    (2, 'Vespertino', '14:00', '18:00'),
    (3, 'Noturno',    '19:00', '23:00');

-- ---------------------------------------------------------------------
-- 10 PROFESSORES
-- ---------------------------------------------------------------------
INSERT INTO professor (matricula, nome, email, titulacao, departamento) VALUES
    ('P001', 'Carlos Silva',     'carlos.silva@fatese.edu.br',     'Doutor',       'Computação'),
    ('P002', 'Ana Souza',        'ana.souza@fatese.edu.br',        'Mestre',       'Computação'),
    ('P003', 'Bruno Lima',       'bruno.lima@fatese.edu.br',       'Mestre',       'Redes e Infraestrutura'),
    ('P004', 'Fernanda Costa',   'fernanda.costa@fatese.edu.br',   'Especialista', 'Línguas'),
    ('P005', 'João Pereira',     'joao.pereira@fatese.edu.br',     'Doutor',       'Engenharia'),
    ('P006', 'Mariana Alves',    'mariana.alves@fatese.edu.br',    'Mestre',       'Gestão'),
    ('P007', 'Rafael Gomes',     'rafael.gomes@fatese.edu.br',     'Especialista', 'Gestão'),
    ('P008', 'Juliana Martins',  'juliana.martins@fatese.edu.br',  'Doutor',       'Ciências Humanas'),
    ('P009', 'Pedro Rocha',      'pedro.rocha@fatese.edu.br',      'Graduado',     'Línguas'),
    ('P010', 'Luciana Ribeiro',  'luciana.ribeiro@fatese.edu.br',  'Doutor',       'Ciências Humanas');

-- ---------------------------------------------------------------------
-- 15 ESPAÇOS FÍSICOS (9 salas comuns + 6 laboratórios)
-- ---------------------------------------------------------------------
INSERT INTO espaco_fisico (codigo, bloco, capacidade, tipo_espaco) VALUES
    ('Sala 101',            'A', 40,  'SALA'),
    ('Sala 102',            'A', 35,  'SALA'),
    ('Sala 103',            'A', 50,  'SALA'),
    ('Sala 104',            'A', 30,  'SALA'),
    ('Sala 201',            'B', 45,  'SALA'),
    ('Sala 202',            'B', 25,  'SALA'),
    ('Sala 203',            'B', 60,  'SALA'),
    ('Auditório Central',   'C', 120, 'SALA'),
    ('Mini-Auditório',      'C', 80,  'SALA'),
    ('Lab 1',               'A', 50,  'LABORATORIO'),
    ('Lab 2',               'A', 40,  'LABORATORIO'),
    ('Lab 3',               'B', 30,  'LABORATORIO'),
    ('Lab 4',               'B', 20,  'LABORATORIO'),
    ('Lab 5',               'C', 35,  'LABORATORIO'),
    ('Lab 6',               'C', 30,  'LABORATORIO');

INSERT INTO sala (id_espaco, possui_projetor)
SELECT e.id_espaco, v.projetor
FROM (VALUES
    ('Sala 101', TRUE),  ('Sala 102', FALSE), ('Sala 103', TRUE),
    ('Sala 104', TRUE),  ('Sala 201', TRUE),  ('Sala 202', FALSE),
    ('Sala 203', TRUE),  ('Auditório Central', TRUE), ('Mini-Auditório', TRUE)
) AS v(codigo, projetor)
JOIN espaco_fisico e ON e.codigo = v.codigo;

INSERT INTO laboratorio (id_espaco, qtd_computadores, tipo_equipamento)
SELECT e.id_espaco, v.qtd, v.equip
FROM (VALUES
    ('Lab 1', 50, 'Desktops Windows/Linux'),
    ('Lab 2', 40, 'Desktops Linux'),
    ('Lab 3', 30, 'Switches e roteadores Cisco'),
    ('Lab 4', 20, 'Bancadas de hardware e eletrônica'),
    ('Lab 5', 35, 'iMacs (macOS)'),
    ('Lab 6', 30, 'Estações com GPU para Ciência de Dados')
) AS v(codigo, qtd, equip)
JOIN espaco_fisico e ON e.codigo = v.codigo;

-- ---------------------------------------------------------------------
-- 10 DISCIPLINAS (5 de 80h = 4h/semana, 5 de 40h = 2h/semana)
-- ---------------------------------------------------------------------
INSERT INTO disciplina (nome, carga_horaria) VALUES
    ('Programação Orientada a Objetos', 80),
    ('Banco de Dados I',                80),
    ('Estruturas de Dados',             80),
    ('Redes de Computadores',           80),
    ('Engenharia de Software',          80),
    ('Ética Profissional',              40),
    ('Inglês Técnico',                  40),
    ('Empreendedorismo',                40),
    ('Metodologia Científica',          40),
    ('Gestão de Projetos',              40);

-- ---------------------------------------------------------------------
-- 5 TURMAS
-- ---------------------------------------------------------------------
INSERT INTO turma (codigo, nome, qtd_alunos, id_turno) VALUES
    ('T1', 'Análise e Desenvolvimento de Sistemas', 40, 1),
    ('T2', 'Engenharia de Software',                25, 1),
    ('T3', 'Redes de Computadores',                 30, 2),
    ('T4', 'Ciência de Dados',                      18, 3),
    ('T5', 'Sistemas de Informação',                45, 3);

-- ---------------------------------------------------------------------
-- 26 ALOCAÇÕES (quadro de horários semanal)
-- Usamos códigos legíveis (turma, disciplina, matrícula, espaço) e o
-- banco resolve os IDs. Todas passam pelas regras de capacidade, turno,
-- carga semanal e choque de horário.
-- ---------------------------------------------------------------------
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco,
                      dia_semana, hora_inicio, hora_fim)
SELECT t.id_turma, d.id_disciplina, p.id_professor, e.id_espaco,
       v.dia, v.inicio::time, v.fim::time
FROM (VALUES
    -- T1 - ADS (Matutino, 40 alunos)
    ('T1', 'Programação Orientada a Objetos', 'P001', 'Lab 1',             'Segunda', '08:00', '12:00'),
    ('T1', 'Banco de Dados I',                'P001', 'Lab 1',             'Terça',   '08:00', '12:00'),
    ('T1', 'Estruturas de Dados',             'P002', 'Lab 2',             'Quarta',  '08:00', '12:00'),
    ('T1', 'Ética Profissional',              'P008', 'Sala 101',          'Quinta',  '08:00', '10:00'),
    ('T1', 'Inglês Técnico',                  'P009', 'Sala 101',          'Quinta',  '10:00', '12:00'),
    -- T2 - Engenharia de Software (Matutino, 25 alunos)
    ('T2', 'Engenharia de Software',          'P002', 'Sala 202',          'Segunda', '08:00', '12:00'),
    ('T2', 'Programação Orientada a Objetos', 'P001', 'Lab 5',             'Quarta',  '08:00', '12:00'),
    ('T2', 'Banco de Dados I',                'P001', 'Lab 6',             'Quinta',  '08:00', '12:00'),
    ('T2', 'Gestão de Projetos',              'P006', 'Mini-Auditório',    'Sexta',   '08:00', '10:00'),
    ('T2', 'Metodologia Científica',          'P010', 'Sala 104',          'Sexta',   '10:00', '12:00'),
    -- T3 - Redes de Computadores (Vespertino, 30 alunos)
    ('T3', 'Redes de Computadores',           'P003', 'Lab 3',             'Segunda', '14:00', '18:00'),
    ('T3', 'Estruturas de Dados',             'P002', 'Lab 2',             'Terça',   '14:00', '18:00'),
    ('T3', 'Engenharia de Software',          'P005', 'Sala 104',          'Quarta',  '14:00', '18:00'),
    ('T3', 'Inglês Técnico',                  'P009', 'Sala 102',          'Quinta',  '14:00', '16:00'),
    ('T3', 'Empreendedorismo',                'P007', 'Sala 102',          'Quinta',  '16:00', '18:00'),
    -- T4 - Ciência de Dados (Noturno, 18 alunos)
    ('T4', 'Banco de Dados I',                'P001', 'Auditório Central', 'Segunda', '19:00', '23:00'),
    ('T4', 'Estruturas de Dados',             'P002', 'Lab 6',             'Terça',   '19:00', '23:00'),
    ('T4', 'Metodologia Científica',          'P010', 'Sala 202',          'Quarta',  '19:00', '21:00'),
    ('T4', 'Ética Profissional',              'P008', 'Sala 202',          'Quarta',  '21:00', '23:00'),
    ('T4', 'Redes de Computadores',           'P003', 'Lab 4',             'Quinta',  '19:00', '23:00'),
    -- T5 - Sistemas de Informação (Noturno, 45 alunos)
    ('T5', 'Engenharia de Software',          'P002', 'Sala 201',          'Segunda', '19:00', '23:00'),
    ('T5', 'Programação Orientada a Objetos', 'P001', 'Lab 1',             'Terça',   '19:00', '23:00'),
    ('T5', 'Redes de Computadores',           'P003', 'Sala 103',          'Quarta',  '19:00', '23:00'),
    ('T5', 'Gestão de Projetos',              'P006', 'Sala 203',          'Quinta',  '19:00', '21:00'),
    ('T5', 'Empreendedorismo',                'P007', 'Sala 203',          'Quinta',  '21:00', '23:00'),
    ('T5', 'Inglês Técnico',                  'P004', 'Sala 103',          'Sexta',   '19:00', '21:00')
) AS v(turma, disciplina, matricula, espaco, dia, inicio, fim)
JOIN turma         t ON t.codigo    = v.turma
JOIN disciplina    d ON d.nome      = v.disciplina
JOIN professor     p ON p.matricula = v.matricula
JOIN espaco_fisico e ON e.codigo    = v.espaco;

-- =====================================================================
--  db_ensalamento - TESTES DAS REGRAS DE NEGÓCIO (todos DEVEM FALHAR)
--  Ótimo para a demonstração ao vivo: mostra o banco recusando os
--  mesmos erros que a planilha manual deixava passar.
--  No pgAdmin, selecione UM teste por vez e pressione F5.
-- =====================================================================

-- TESTE 1 - Choque de horário do PROFESSOR
-- Carlos Silva já dá aula na Segunda 08-12 (T1). Tentamos colocá-lo na T2 às 10h.
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T2'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Ética Profissional'),
        (SELECT id_professor FROM professor WHERE nome = 'Carlos Silva'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Sala 104'),
        'Segunda', '10:00', '12:00');
-- Esperado: ERRO ... violates exclusion constraint "ex_choque_professor"

-- TESTE 2 - Choque de ESPAÇO FÍSICO
-- O Lab 1 já está ocupado na Segunda 08-12 pela T1.
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T2'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Ética Profissional'),
        (SELECT id_professor FROM professor WHERE nome = 'Juliana Martins'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Lab 1'),
        'Segunda', '08:00', '10:00');
-- Esperado: ERRO ... violates exclusion constraint "ex_choque_espaco"

-- TESTE 3 - Turma MAIOR que a capacidade da sala
-- T5 tem 45 alunos; o Lab 4 comporta 20.
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T5'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Ética Profissional'),
        (SELECT id_professor FROM professor WHERE nome = 'Juliana Martins'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Lab 4'),
        'Sexta', '21:00', '23:00');
-- Esperado: ERRO: Capacidade insuficiente: Lab 4 comporta 20 alunos, mas a turma tem 45.

-- TESTE 4 - Aula FORA DO TURNO da turma
-- T1 é Matutino (08-12); tentamos marcar aula às 19h.
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T1'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Gestão de Projetos'),
        (SELECT id_professor FROM professor WHERE nome = 'Mariana Alves'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Sala 101'),
        'Sexta', '19:00', '21:00');
-- Esperado: ERRO: Horário fora do turno: a turma é do turno Matutino (08:00:00 às 12:00:00).

-- TESTE 5 - Carga semanal excedida
-- Ética (40h) exige 2h/semana e a T1 já tem 2h alocadas.
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T1'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Ética Profissional'),
        (SELECT id_professor FROM professor WHERE nome = 'Juliana Martins'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Sala 101'),
        'Sexta', '08:00', '10:00');
-- Esperado: ERRO: Carga semanal excedida: a disciplina exige 2 h/semana para esta turma.

-- TESTE 6 - Duração fora do intervalo de 1 a 4 horas (aula de 30 min)
-- (Aulas com mais de 4h também são barradas por este CHECK.)
INSERT INTO alocacao (id_turma, id_disciplina, id_professor, id_espaco, dia_semana, hora_inicio, hora_fim)
VALUES ((SELECT id_turma FROM turma WHERE codigo = 'T1'),
        (SELECT id_disciplina FROM disciplina WHERE nome = 'Gestão de Projetos'),
        (SELECT id_professor FROM professor WHERE nome = 'Mariana Alves'),
        (SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Sala 101'),
        'Sábado', '08:00', '08:30');
-- Esperado: ERRO ... violates check constraint "ck_aloc_duracao"

-- TESTE 7 - Capacidade negativa
INSERT INTO espaco_fisico (codigo, bloco, capacidade, tipo_espaco)
VALUES ('Sala X', 'D', -10, 'SALA');
-- Esperado: ERRO ... violates check constraint "ck_espaco_capacidade"

-- TESTE 8 - Disciplina com carga diferente de 40h/80h
INSERT INTO disciplina (nome, carga_horaria) VALUES ('Cálculo I', 60);
-- Esperado: ERRO ... violates check constraint "ck_disciplina_carga"

-- TESTE 9 - Especialização inconsistente: cadastrar um LABORATÓRIO como SALA
INSERT INTO sala (id_espaco, possui_projetor)
VALUES ((SELECT id_espaco FROM espaco_fisico WHERE codigo = 'Lab 1'), TRUE);
-- Esperado: ERRO ... violates foreign key constraint "fk_sala_espaco"

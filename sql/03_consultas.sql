-- =====================================================================
--  db_ensalamento - CONSULTAS E RELATÓRIOS ESTRATÉGICOS (DQL)
--  Dica pgAdmin: selecione UMA consulta e pressione F5 para ver o
--  Data Output dela (é desse resultado que sai o print do relatório).
-- =====================================================================

-- =====================================================================
-- CONSULTAS SIMPLES
-- =====================================================================

-- 1. Listagem de Professores
SELECT nome, matricula, titulacao
FROM professor
ORDER BY nome;

-- 2. Inventário de Infraestrutura (maior -> menor capacidade)
SELECT e.codigo,
       e.bloco,
       e.capacidade,
       CASE e.tipo_espaco WHEN 'SALA' THEN 'Sala Comum' ELSE 'Laboratório' END AS tipo
FROM espaco_fisico e
ORDER BY e.capacidade DESC, e.codigo;

-- 3. Filtro de Disciplinas de 80h (4h semanais)
SELECT nome, carga_horaria, horas_semanais
FROM disciplina
WHERE carga_horaria = 80
ORDER BY nome;

-- =====================================================================
-- CONSULTAS INTERMEDIÁRIAS (JOINs)
-- =====================================================================

-- 4. Grade Curricular por Turma
SELECT DISTINCT
       t.codigo || ' - ' || t.nome AS turma,
       d.nome                      AS disciplina,
       p.nome                      AS professor
FROM alocacao a
JOIN turma      t ON t.id_turma      = a.id_turma
JOIN disciplina d ON d.id_disciplina = a.id_disciplina
JOIN professor  p ON p.id_professor  = a.id_professor
ORDER BY turma, disciplina;

-- 5. Capacidade total por Tipo de Sala
SELECT CASE e.tipo_espaco WHEN 'SALA' THEN 'Sala Comum' ELSE 'Laboratório' END AS tipo_espaco,
       COUNT(*)          AS qtd_espacos,
       SUM(e.capacidade) AS capacidade_total
FROM espaco_fisico e
GROUP BY e.tipo_espaco
ORDER BY capacidade_total DESC;

-- 6. Agenda do Professor "Carlos Silva" no turno Matutino
SELECT a.dia_semana,
       a.hora_inicio,
       a.hora_fim,
       e.codigo AS sala,
       t.codigo AS turma,
       d.nome   AS disciplina
FROM alocacao a
JOIN professor     p  ON p.id_professor  = a.id_professor
JOIN turma         t  ON t.id_turma      = a.id_turma
JOIN turno         tn ON tn.id_turno     = t.id_turno
JOIN espaco_fisico e  ON e.id_espaco     = a.id_espaco
JOIN disciplina    d  ON d.id_disciplina = a.id_disciplina
WHERE p.nome  = 'Carlos Silva'
  AND tn.nome = 'Matutino'
ORDER BY array_position(ARRAY['Segunda','Terça','Quarta','Quinta','Sexta','Sábado']::varchar[],
                        a.dia_semana),
         a.hora_inicio;

-- 7. Demanda de Alunos por Turno
SELECT tn.nome                         AS turno,
       COUNT(t.id_turma)               AS qtd_turmas,
       COALESCE(SUM(t.qtd_alunos), 0)  AS total_alunos
FROM turno tn
LEFT JOIN turma t ON t.id_turno = tn.id_turno
GROUP BY tn.id_turno, tn.nome
ORDER BY tn.id_turno;

-- =====================================================================
-- CONSULTAS ESTRATÉGICAS
-- =====================================================================

-- 8. Auditoria de Desperdício de Espaço (sobram mais de 15 lugares)
SELECT t.codigo || ' - ' || t.nome       AS turma,
       t.qtd_alunos,
       e.codigo                          AS sala,
       e.capacidade,
       e.capacidade - t.qtd_alunos       AS lugares_ociosos,
       a.dia_semana,
       a.hora_inicio,
       a.hora_fim
FROM alocacao a
JOIN turma         t ON t.id_turma  = a.id_turma
JOIN espaco_fisico e ON e.id_espaco = a.id_espaco
WHERE e.capacidade - t.qtd_alunos > 15
ORDER BY lugares_ociosos DESC;

-- 9. Gargalo de Infraestrutura: horas ocupadas por sala na semana
--    (LEFT JOIN para também mostrar as salas ociosas, com 0 h)
SELECT e.codigo AS sala,
       COALESCE(SUM(EXTRACT(EPOCH FROM (a.hora_fim - a.hora_inicio)) / 3600), 0)::int
                AS total_horas_semana
FROM espaco_fisico e
LEFT JOIN alocacao a ON a.id_espaco = e.id_espaco
GROUP BY e.id_espaco, e.codigo
ORDER BY total_horas_semana DESC, e.codigo;

-- 10. Risco de Sobrecarga Docente (mais de 20 h/semana)
--     Cruza alocação com disciplina: horas efetivamente alocadas e
--     as disciplinas (com sua carga horária) que compõem esse total.
SELECT p.nome                                                      AS professor,
       COUNT(*)                                                    AS qtd_aulas,
       SUM(EXTRACT(EPOCH FROM (a.hora_fim - a.hora_inicio)) / 3600)::int
                                                                   AS horas_semanais,
       STRING_AGG(DISTINCT d.nome || ' (' || d.carga_horaria || 'h)', ', ')
                                                                   AS disciplinas
FROM alocacao a
JOIN professor  p ON p.id_professor  = a.id_professor
JOIN disciplina d ON d.id_disciplina = a.id_disciplina
GROUP BY p.id_professor, p.nome
HAVING SUM(a.hora_fim - a.hora_inicio) > INTERVAL '20 hours'
ORDER BY horas_semanais DESC;

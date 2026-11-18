# Modelo Lógico (versão de entrega)

Notação: **PK** = chave primária, **FK** = chave estrangeira, **UK** = valor único.

```
turno         (id_turno PK, nome UK, hora_inicio, hora_fim)
professor     (id_professor PK, matricula UK, nome, email UK, titulacao, departamento)
espaco_fisico (id_espaco PK, codigo UK, bloco, capacidade, tipo_espaco)
sala          (id_espaco PK/FK -> espaco_fisico, tipo_espaco, possui_projetor)
laboratorio   (id_espaco PK/FK -> espaco_fisico, tipo_espaco, qtd_computadores, tipo_equipamento)
disciplina    (id_disciplina PK, nome UK, carga_horaria, horas_semanais [calculada])
turma         (id_turma PK, codigo UK, nome, qtd_alunos, id_turno FK -> turno)
alocacao      (id_alocacao PK,
               id_turma FK -> turma, id_disciplina FK -> disciplina,
               id_professor FK -> professor, id_espaco FK -> espaco_fisico,
               dia_semana, hora_inicio, hora_fim)
```

## Do DER para as tabelas

| No DER | Cardinalidade | Como virou tabela |
| --- | --- | --- |
| Turno possui Turmas | 1:N | `id_turno` como FK em `turma` |
| Espaço Físico é Sala ou Laboratório | especialização total e exclusiva | `sala` e `laboratorio` usam `id_espaco` como PK e FK; a FK composta `(id_espaco, tipo_espaco)` impede cadastrar um laboratório como sala |
| Turma, Disciplina, Professor e Espaço se encontram numa aula | N:N entre os quatro | tabela associativa `alocacao` com quatro FKs |

## Decisões

- **`turno` em tabela própria:** o horário de cada turno fica guardado uma vez só, e dá para validar se a aula está dentro dele.
- **`sala` e `laboratorio` separadas:** cada uma tem suas colunas, sem campo vazio na tabela mãe.
- **`alocacao` com PK própria:** mais simples de referenciar do que uma chave composta de quatro colunas.
- **`horas_semanais` calculada** (`carga_horaria / 20`): 40h dá 2h por semana, 80h dá 4h.

## Regras e onde cada uma é garantida

| Regra | Onde |
| --- | --- |
| Capacidade maior que zero | CHECK em `espaco_fisico` |
| Tipo do espaço é SALA ou LABORATORIO | CHECK em `espaco_fisico` |
| Carga horária é 40 ou 80 | CHECK em `disciplina` |
| Turno é Matutino, Vespertino ou Noturno | CHECK em `turno` |
| Titulação é Graduado, Especialista, Mestre ou Doutor | CHECK em `professor` |
| Aula dura de 1 a 4 horas, e termina depois de começar | CHECK em `alocacao` |
| Matrícula e e-mail únicos | UNIQUE em `professor` |
| Mesmo professor em dois lugares no mesmo horário | EXCLUDE `ex_choque_professor` |
| Duas aulas no mesmo espaço ao mesmo tempo | EXCLUDE `ex_choque_espaco` |
| Mesma turma com duas aulas sobrepostas | EXCLUDE `ex_choque_turma` |
| Turma maior que a capacidade do espaço | trigger `tg_valida_alocacao` (R1) |
| Aula fora do turno da turma | trigger (R2) |
| Mais horas semanais do que a carga da disciplina | trigger (R3) |

As três últimas dependem de outras tabelas ou de outras linhas, e um CHECK só enxerga a própria linha. Por isso ficam no trigger.

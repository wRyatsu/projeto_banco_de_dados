# db_ensalamento: Banco de Dados do Sistema de Ensalamento Acadêmico

## Entrega e equipe

**Data de entrega:** 19/11/2026 · Faculdade de Tecnologia do SENAC (FATESE) · Prof. Carlos Bruno Oliveira Lopes

| Equipe | Modelo | Integrantes |
| --- | --- | --- |
| Equipe 1 | Conceitual (DER no brModelo) | Rickson (líder), Ryan Façanha, Francisco Emanuel, Taquita, Emanuel |
| Equipe 2 | Lógico (tabelas, PK e FK) | Matheus (líder), Tiago, Sara, Emanuelly, Sabrina, Letícia |
| Equipe 3 | Físico (SQL no PostgreSQL) | Victor (líder), Diego, Hatus, Cleyton, Danielly |

Divisão de tarefas: [`EQUIPES.md`](EQUIPES.md).

## Contribuidores

| Integrante | GitHub |
| --- | --- |
| Ryan Façanha | [@wRyatsu](https://github.com/wRyatsu) |
| Matheus | [@Matheus1357](https://github.com/Matheus1357) |
| Sara | [@sara2003s](https://github.com/sara2003s) |
| Taquita | [@ltaquita](https://github.com/ltaquita) |
| Emanuelly | [@manuellybraga696-spec](https://github.com/manuellybraga696-spec) |
| Tiago | [@tdaptdap1](https://github.com/tdaptdap1) |
| Danielly | [@Danegio](https://github.com/Danegio) |
| Emanuel | [@EmanuelTorresMarques](https://github.com/EmanuelTorresMarques) |

## Relatórios

| Arquivo | Conteúdo |
| --- | --- |
| [`relatorios/Relatorio_1_Modelo_Conceitual.docx`](relatorios/Relatorio_1_Modelo_Conceitual.docx) | Introdução, entidades, cardinalidades, regras e DER |
| [`relatorios/Relatorio_2_Modelo_Logico.docx`](relatorios/Relatorio_2_Modelo_Logico.docx) | Esquema relacional, PK/FK, resolução do N:N |
| [`relatorios/Relatorio_3_Modelo_Fisico.docx`](relatorios/Relatorio_3_Modelo_Fisico.docx) | DDL, DML, 10 consultas com prints, testes, dificuldades, melhorias e conclusão |

Modelo lógico em texto: [`docs/modelo_logico.md`](docs/modelo_logico.md).


Projeto da disciplina de Banco de Dados (FATESE / ADS). Ele substitui a planilha manual de ensalamento por um banco **PostgreSQL** que **impede no próprio banco** os erros clássicos do início do semestre:

| Problema da planilha | Como o banco impede |
|---|---|
| Mesmo professor em duas turmas no mesmo horário | `EXCLUDE` constraint `ex_choque_professor` |
| Duas aulas na mesma sala ao mesmo tempo | `EXCLUDE` constraint `ex_choque_espaco` |
| Mesma turma com duas aulas sobrepostas | `EXCLUDE` constraint `ex_choque_turma` |
| Turma maior que a capacidade da sala | Trigger `tg_valida_alocacao` (regra R1) |
| Aula fora do turno da turma | Trigger `tg_valida_alocacao` (regra R2) |
| Disciplina com mais horas do que a carga exige | Trigger `tg_valida_alocacao` (regra R3) |
| Capacidade negativa, aula com menos de 1h ou mais de 4h, carga diferente de 40h/80h | `CHECK` constraints |

## Estrutura do repositório

```
db_ensalamento/
├── README.md
├── sql/
│   ├── 01_ddl.sql            # Fase 3: criação das tabelas e constraints
│   ├── 02_dml.sql            # Fase 4: povoamento (dados fictícios)
│   ├── 03_consultas.sql      # As 10 consultas (DQL)
│   └── 04_testes_regras.sql  # Inserções inválidas que DEVEM ser recusadas
└── docs/
    ├── der_conceitual.png    # Fase 1: DER (referência para montar no brModelo)
    ├── modelo_logico.png     # Fase 2: esquema lógico
    └── *.dot                 # Fontes dos diagramas (Graphviz)
```

## Como rodar

**Pré-requisitos:** PostgreSQL 13 ou superior + pgAdmin 4. A extensão `btree_gist` já vem com a instalação padrão do PostgreSQL.

1. No pgAdmin, clique com o botão direito em **Databases → Create → Database…** e crie `db_ensalamento`
   (ou rode `CREATE DATABASE db_ensalamento;`).
2. Selecione o banco `db_ensalamento` e abra o **Query Tool**.
3. Abra e execute (F5), nesta ordem:
   1. `sql/01_ddl.sql`
   2. `sql/02_dml.sql`
4. Abra `sql/03_consultas.sql`, **selecione uma consulta por vez** e pressione F5 para ver o *Data Output*.
5. (Opcional, para a demonstração) Abra `sql/04_testes_regras.sql` e execute **um teste por vez**. Todos devem dar erro.

Pelo terminal:

```bash
createdb db_ensalamento
psql -d db_ensalamento -f sql/01_ddl.sql
psql -d db_ensalamento -f sql/02_dml.sql
psql -d db_ensalamento -f sql/03_consultas.sql
```

> O `01_ddl.sql` é reexecutável: apaga e recria tudo. Para "zerar" o banco, rode de novo o 01 e depois o 02.

## Modelo lógico

```
turno         (id_turno PK, nome UK, hora_inicio, hora_fim)
professor     (id_professor PK, matricula UK, nome, email UK, titulacao, departamento)
espaco_fisico (id_espaco PK, codigo UK, bloco, capacidade, tipo_espaco)
sala          (id_espaco PK/FK → espaco_fisico, tipo_espaco, possui_projetor)
laboratorio   (id_espaco PK/FK → espaco_fisico, tipo_espaco, qtd_computadores, tipo_equipamento)
disciplina    (id_disciplina PK, nome UK, carga_horaria, horas_semanais [calculada])
turma         (id_turma PK, codigo UK, nome, qtd_alunos, id_turno FK → turno)
alocacao      (id_alocacao PK,
               id_turma FK → turma, id_disciplina FK → disciplina,
               id_professor FK → professor, id_espaco FK → espaco_fisico,
               dia_semana, hora_inicio, hora_fim)
```

**Decisões de modelagem**

- **Especialização Sala/Laboratório (total e exclusiva):** cada subclasse herda a PK de `espaco_fisico`. A FK composta `(id_espaco, tipo_espaco)` impede, por exemplo, cadastrar o "Lab 1" como sala.
- **Alocacao como tabela associativa:** resolve o relacionamento N:N entre Turma, Disciplina, Professor e Espaço, em um dia e faixa de horário.
- **Turno como tabela própria:** guarda o horário de cada turno, o que permite validar se a aula está dentro dele.
- **`horas_semanais` calculada** (`carga_horaria / 20`): 40h → 2h por semana, 80h → 4h por semana, sem risco de digitação errada.

## Dados de teste

10 professores · 15 espaços (9 salas e 6 laboratórios) · 10 disciplinas (5 de 40h e 5 de 80h) · 3 turnos · 5 turmas · 26 alocações.

Os dados foram montados para que as consultas estratégicas tenham resultado:
- **Q8:** a T4 (18 alunos) no Auditório Central (120) e a T2 (25) no Mini-Auditório (80).
- **Q10:** Carlos Silva tem 24 h por semana. Ana Souza tem exatamente 20 h e **não** aparece, porque a regra é "mais de 20".

# Guia de Execução de Migrations

Este documento explica como aplicar a estrutura do banco de dados em diferentes ambientes.

## 1. Desenvolvimento Local (Recomendado)

A maneira mais fácil de executar as migrations localmente é usando o **Docker Compose**. O arquivo `docker-compose.yml` na raiz do projeto já está configurado para executar automaticamente o script inicial.

### Como executar:
1. Certifique-se de que o Docker está instalado e rodando.
2. Na raiz do projeto, execute:
   ```bash
   docker-compose up -d
   ```
3. O script `database/migrations/001_initial_schema.sql` será executado automaticamente assim que o container do Postgres subir pela primeira vez.

### Como resetar o banco:
Se precisar apagar tudo e recomeçar (cuidado, apaga todos os dados):
```bash
docker-compose down -v
docker-compose up -d
```

---

## 2. Ambiente Cloud (Staging/Prod)

Em ambientes AWS, você tem duas opções principais:

### Opção A: Via CI/CD (GitHub Actions)
Configure um workflow que utilize ferramentas como **Flyway**, **Liquibase** ou o próprio CLI do seu framework (Prisma, TypeORM) para aplicar os arquivos SQL na `url` do RDS provisionado pelo Terraform.

### Opção B: Manual (via Bastion/VPN)
Se você estiver conectado à VPC da AWS via VPN ou Bastion Host, pode usar um cliente SQL (DBeaver, pgAdmin) para se conectar ao endpoint do RDS e executar o conteúdo do arquivo `.sql`.

---

## 3. Próximos Passos (Evolução)

Para facilitar o dia a dia, recomendaremos o uso de uma ferramenta de migração programática:
- **Prisma**: `npx prisma migrate dev`
- **Knex**: `knex migrate:latest`
- **Flyway**: `flyway migrate`

Isso permite versionar alterações individuais (ex: adicionar uma coluna) sem resetar o banco.

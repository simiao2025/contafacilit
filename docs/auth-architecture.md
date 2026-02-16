# ContaFacilit — Arquitetura de Autenticação e Segurança

> **Versão:** 1.0  
> **Status:** Design de Segurança Finalizado  
> **Framework:** NestJS + Passport.js

---

## 1. Fluxo de Autenticação (JWT + Rotação)

O sistema utiliza **Refresh Tokens Rotativos** para balancear segurança e experiência do usuário.

### 1.1 Login
1. O usuário envia `email` e `password`.
2. O sistema valida o hash (Bcrypt).
3. Se válido:
   - Gera um `AccessToken` (Assinado com HS256, expira em 15m).
   - Gera um `RefreshToken` cryptographically strong (Opaque Token).
   - Armazena o hash do `RefreshToken` no banco (`refresh_tokens`).
   - Retorna ambos para o cliente.

### 1.2 Rotação de Refresh Token
Para mitigar **Replay Attacks**:
1. O cliente envia o `RefreshToken` antigo.
2. O sistema verifica se o token existe e não está revogado.
3. **Estratégia de Detecção de Roubo**:
   - Se um `RefreshToken` for usado mais de uma vez, o sistema assume que houve um vazamento.
   - **Ação**: Revoga todos os tokens ativos daquele usuário imediatamente.
4. Se válido:
   - Revoga o token antigo (coluna `replaced_by_token_id`).
   - Gera um novo par de tokens.

---

## 2. Multi-tenancy & Contexto

O `AccessToken` carrega o `organization_id` no payload:
```json
{
  "sub": "user_uuid",
  "org": "org_uuid",
  "role": "ADMIN",
  "iat": 1516239022,
  "exp": 1516240022
}
```

### 2.1 Tenant Middleware
Um interceptor ou middleware extrai o `org` do token e o injeta no objeto `Request`. Isso garante que camadas inferiores (Services/Repositories) sempre operem sob o escopo correto.

---

## 3. Controle de Acesso (RBAC)

Hierarquia de Permissões:
| Role | Descrição |
| :--- | :--- |
| **ADMIN** | Gestão total da organização, usuários e configurações fiscais. |
| **CONTADOR** | Realiza lançamentos, apurações e gera relatórios. |
| **COLABORADOR** | Acesso limitado a visualização e lançamentos básicos. |

---

## 4. Implementação NestJS (Estrutura Recomendada)

### 4.1 Decorators
- `@Public()`: Ignora o `JwtAuthGuard`.
- `@Roles(Role.ADMIN)`: Define permissões necessárias.

### 4.2 Guards
- `ThrottlerGuard`: Rate limiting para `/auth/login`.
- `JwtAuthGuard`: Validação de Access Token.
- `RolesGuard`: Verificação de RBAC via metadados.

---

## 5. Estratégia de Segurança (Hardening)

1.  **Secrets Management**: Uso de **AWS Secrets Manager** para armazenar `JWT_SECRET` e `REFRESH_SECRET`, injetados via `ConfigService`.
2.  **HTTPS Only**: Tokens nunca devem trafegar em canais não criptografados.
3.  **Bcrypt Cost**: Fator de custo (Salt rounds) ajustado para `12` para balancear latência e resistência a brute-force.
4.  **Audit Trail**: Logs de auditoria para cada login e rotação de token via tabela `audit_logs`.
5.  **Revogação Ativa**: Capacidade de invalidar sessões remotamente via API administrativa.

---

## 6. Checklist de Implementação

- [ ] Instalar `@nestjs/jwt`, `@nestjs/passport` e `bcrypt`.
- [ ] Configurar `JwtStrategy` e `LocalStrategy`.
- [ ] Implementar `AuthRepository` para persistência de tokens.
- [ ] Criar `CurrentOrganization` decorator para facilitar acesso ao tenant.

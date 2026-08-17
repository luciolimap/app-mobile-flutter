# Orbytis — Desafio Técnico Mobile: Mini App de Inspeção de Campo

[![CI](https://github.com/luciolimap/app-mobile-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/luciolimap/app-mobile-flutter/actions/workflows/ci.yml)

App Flutter (Android) para um técnico de campo: login, lista de ordens de
serviço, formulário de inspeção (texto + foto + GPS), persistência local
com fila de sincronização e histórico com status.

## Estrutura do repositório

```
.
├── DESAFIO_CANDIDATO.md   # enunciado original
├── CONTRATO_API.md        # contrato da API mock
├── mock-api/              # API mock (Node/Express) fornecida no desafio
└── mobile/                # app Flutter
```

## Como rodar

### 1. Subir a API mock

```bash
cd mock-api
npm install
npm start
```

Sobe em `http://localhost:3000`. Credenciais de teste:

| E-mail                     | Senha      |
|-----------------------------|------------|
| `tecnico@orbytis.com.br`    | `123456`   |
| `admin@orbytis.com.br`      | `admin123` |

### 2. Rodar o app

```bash
cd mobile
flutter pub get
flutter run
```

A base URL da API está fixa em `lib/core/api/api_client.dart`
(`kApiBaseUrl`). Por padrão aponta para `http://127.0.0.1:3000` (o
`localhost` do próprio dispositivo), pensado para **dispositivo físico**
com:

```bash
adb reverse tcp:3000 tcp:3000
```

Esse comando encaminha o `localhost:3000` do celular para o
`localhost:3000` da máquina, através da própria conexão ADB (USB ou
sem fio) — funciona mesmo quando o roteador isola tráfego entre Wi-Fi
e cabo (isolamento de AP), que foi o caso aqui durante os testes.

Se for testar no **emulador Android** em vez de dispositivo físico,
troque `kApiBaseUrl` para `http://10.0.2.2:3000` (o alias que o
emulador usa para acessar o `localhost` do host).

## Arquitetura

```
lib/
  core/
    api/          # Dio client com interceptor de auth + normalização de erros
    database/     # Drift (SQLite): cache de OS + fila de inspeções
    storage/      # flutter_secure_storage (token JWT)
    services/     # ConnectivityService, LocationService
  features/
    auth/         # login, guarda de sessão, logout
    work_orders/  # lista de OS (cache-first + refresh da API)
    inspection/   # formulário de inspeção (foto, GPS, rascunho/conclusão)
    sync/         # SyncService — fila de sincronização
    history/      # histórico local + filtro + retry
  app.dart         # injeção de dependências + MaterialApp
  home_shell.dart  # navegação (Ordens de Serviço / Histórico) pós-login
  main.dart
```

**Gerenciamento de estado — BLoC (`flutter_bloc`).** Cada feature tem seu
bloc isolado; a UI só reage a `state` e dispara `event`s, sem lógica de
negócio nos widgets.

**Persistência local — Drift.** Banco SQLite type-safe, com duas tabelas:
`work_order_cache` (cópia local da lista de OS, permite ver a lista
offline) e `inspections` (a fila de sincronização propriamente dita).
Escolhido em vez de `sqflite` puro por dar consulta tipada e *streams*
reativos (`watch()`), o que elimina a necessidade de gerenciar
`setState`/refresh manual — a UI de histórico e a lista de OS já são
atualizadas automaticamente quando o banco muda.

**HTTP — Dio.** Interceptor único injeta o `Authorization: Bearer <token>`
em toda rota exceto `/auth/login`; erros são normalizados em
`ApiException` (com distinção de erro de rede vs. erro do servidor vs.
erros de validação por campo).

**Token — `flutter_secure_storage`.** Persistido de forma criptografada;
`AuthGate` (em `app.dart`) bloqueia todo o app até existir uma sessão
válida — sem token, a única tela acessível é o login.

## Fila de sincronização

Cada inspeção nasce localmente com um `clientId` (UUID gerado no
device) e um `status`:

- `draft` — rascunho; **nunca** é enviado à API.
- `pending` — pronta para sincronizar.
- `synced` — confirmada pelo servidor (guarda o `serverId` retornado).
- `failed` — a última tentativa falhou (mensagem de erro legível salva
  junto).

Fluxo:

1. Ao tocar **"Concluir inspeção"**, o registro é salvo como `pending` e
   o app tenta sincronizar imediatamente (`SyncService.syncAll`).
2. Se não houver conexão, a tentativa falha normalmente e o item vira
   `failed` — mas ele continua elegível para novas tentativas.
3. `SyncService` escuta `connectivity_plus`: toda vez que a conectividade
   volta, ele automaticamente reprocessa **todos** os itens `pending`
   **e** `failed`.
4. A tela de Histórico tem um botão de sync manual (ícone de refresh no
   topo) e um botão **"Tentar novamente"** por item `failed`.
5. Reenvio sempre reutiliza o mesmo `clientId` — o mock trata isso como
   idempotente (retorna o registro já existente em vez de duplicar), e
   o app faz o mesmo request de sempre, então nunca duplica no servidor.

O envio é `multipart/form-data` (campo `photo` com o arquivo), conforme
o contrato preferencial da API.

## Testes

```bash
cd mobile
flutter test
```

32 testes de BLoC/serviço/widget cobrindo o que mais pesa na avaliação:

- **`SyncService`** (`test/features/sync/sync_service_test.dart`): sucesso
  marca `synced` com `serverId`; falha marca `failed` com a mensagem de
  erro; rascunhos nunca são enviados; um item `failed` volta a ser
  tentado no próximo `syncAll()`; `retry(id)` afeta só o item alvo.
- **`InspectionFormBloc`**: validação de "Concluir inspeção" (observação
  ≥ mínimo do schema, foto obrigatória, localização obrigatória), "Salvar
  rascunho" sem essas exigências, o alerta de geofence, e a aplicação do
  form-schema dinâmico (labels/opções/mínimo de caracteres).
- **`AuthBloc`**: restauração de sessão, login (sucesso/falha), logout.
- **`HistoryBloc`**: carregamento a partir do banco local, filtro por
  status, sync manual e retry disparando o `SyncService` corretamente.
- **`WorkOrdersBloc`**: refresh bem-sucedido, falha com cache vazio,
  e o comportamento cache-first (mantém os itens já cacheados na tela
  quando um refresh subsequente falha — ex. ficou offline).
- **Widget tests da lista de OS**: os quatro estados de UI (carregando,
  erro com retry, vazio, lista preenchida com os rótulos em pt-BR).

### CI

`.github/workflows/ci.yml` roda `flutter analyze` + `flutter test` a
cada push/PR na `master`. Não precisa do mock-api nem de emulador — os
32 testes são puramente unitários/BLoC (banco Drift em memória, `ApiClient`
mockado com `mocktail`).

## Outras funcionalidades implementadas

- **Geofence**: ao capturar a localização no formulário de inspeção, o
  app calcula a distância até o ponto da OS (`Geolocator.distanceBetween`)
  e exibe um aviso (não bloqueia o envio) se estiver a mais de 200 m.
- **Dark mode**: `ThemeMode.system` — segue o tema do aparelho
  automaticamente, com fundo de maior contraste no escuro para uso
  outdoor.
- **Formulário dinâmico via `form-schema`**: o formulário de inspeção
  busca `GET /work-orders/:id/form-schema` e usa os rótulos, o mínimo
  de caracteres da observação e as opções de condição vindos da API,
  em vez de fixos no código. A busca nunca bloqueia o formulário — se
  falhar (ex. offline), os valores padrão de hoje continuam valendo
  sem nenhuma diferença visível. `condition` continua opcional na UI
  mesmo o schema marcando como obrigatório, porque o contrato de
  `POST /inspections` trata esse campo como opcional.
- **Continuar rascunho**: a tela da OS lista as inspeções locais já
  feitas para ela, com um botão para reabrir e editar um rascunho em
  vez de sempre criar um registro novo.
- **CI**: GitHub Actions rodando `flutter analyze` + `flutter test` em
  todo push/PR (veja a seção Testes).

## O que ficou pendente / o que faria com mais tempo

O desafio pede, explicitamente, fluxo completo e bem estruturado em vez
de muita feature pela metade. Priorizei nessa ordem: (1) 100% do escopo
obrigatório com testes, (2) os itens de escopo desejável/opcional mais
alinhados ao perfil da vaga — BLoC, geofence, dark mode, form-schema
dinâmico, CI. Dois itens do escopo desejável ficaram fora por decisão
consciente, não por falta de tempo:

- **Sem Freezed/codegen de modelos**: `User` e `WorkOrder` são classes
  simples com `fromJson`/`Equatable`. Evita um segundo gerador de
  código concorrendo com o do Drift e mantém o build previsível — troca
  direta, sem custo de robustez pro escopo obrigatório.
- **Sem `go_router`**: `Navigator` padrão + um `AuthGate` simples que
  troca entre `LoginPage` e `HomeShell` conforme o `AuthBloc` cobre o
  requisito de bloqueio de rota sem token com bem menos configuração
  do que um router declarativo.
- **Fila de sync trata falha de rede e erro de validação do servidor
  da mesma forma** (`failed`, reprocessado automaticamente no próximo
  `syncAll()` ou ao reconectar). Decisão deliberada: garante que nada
  se perde e tudo é retentado, ao custo de não diferenciar a causa raiz
  na UI — dá pra refinar isso mantendo o mesmo modelo de dados.

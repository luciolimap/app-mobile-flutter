# Orbytis — Desafio Técnico Mobile: Mini App de Inspeção de Campo

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

21 testes de BLoC/serviço cobrindo o que mais pesa na avaliação:

- **`SyncService`** (`test/features/sync/sync_service_test.dart`): sucesso
  marca `synced` com `serverId`; falha marca `failed` com a mensagem de
  erro; rascunhos nunca são enviados; um item `failed` volta a ser
  tentado no próximo `syncAll()`; `retry(id)` afeta só o item alvo.
- **`InspectionFormBloc`**: validação de "Concluir inspeção" (observação
  ≥ 10 caracteres, foto obrigatória, localização obrigatória), "Salvar
  rascunho" sem essas exigências, e o alerta de geofence.
- **`AuthBloc`**: restauração de sessão, login (sucesso/falha), logout.
- **`HistoryBloc`**: carregamento a partir do banco local, filtro por
  status, sync manual e retry disparando o `SyncService` corretamente.

## Outras funcionalidades implementadas

- **Geofence**: ao capturar a localização no formulário de inspeção, o
  app calcula a distância até o ponto da OS (`Geolocator.distanceBetween`)
  e exibe um aviso (não bloqueia o envio) se estiver a mais de 200 m.
- **Dark mode**: `ThemeMode.system` — segue o tema do aparelho
  automaticamente, com fundo de maior contraste no escuro para uso
  outdoor.

## O que ficou pendente / o que faria com mais tempo

O desafio pede, explicitamente, fluxo completo e bem estruturado em vez
de muita feature pela metade. Priorizei nessa ordem: (1) 100% do escopo
obrigatório com testes, (2) os itens de escopo desejável mais alinhados
ao perfil da vaga — BLoC, geofence, dark mode. Alguns itens do escopo
desejável/opcional ficaram fora por decisão consciente, não por falta
de tempo:

- **Sem Freezed/codegen de modelos**: `User` e `WorkOrder` são classes
  simples com `fromJson`/`Equatable`. Evita um segundo gerador de
  código concorrendo com o do Drift e mantém o build previsível — troca
  direta, sem custo de robustez pro escopo obrigatório.
- **Sem `go_router`**: `Navigator` padrão + um `AuthGate` simples que
  troca entre `LoginPage` e `HomeShell` conforme o `AuthBloc` cobre o
  requisito de bloqueio de rota sem token com bem menos configuração
  do que um router declarativo.
- **Campos fixos em vez de dinâmicos via `form-schema`**: o mock expõe
  `GET /work-orders/:id/form-schema`; os campos fixos do formulário já
  cobrem exatamente esse schema (observação, condição, foto,
  localização), então a camada dinâmica não mudaria o comportamento.
- **Fila de sync trata falha de rede e erro de validação do servidor
  da mesma forma** (`failed`, reprocessado automaticamente no próximo
  `syncAll()` ou ao reconectar). Decisão deliberada: garante que nada
  se perde e tudo é retentado, ao custo de não diferenciar a causa raiz
  na UI — dá pra refinar isso mantendo o mesmo modelo de dados.
- **Próximo passo natural do repositório**: CI (GitHub Actions rodando
  `flutter analyze` + `flutter test` a cada push) e testes de
  `WorkOrdersBloc`/widget tests, complementando os 21 testes já
  cobrindo a modelagem offline/sync (o critério de maior peso na
  avaliação).

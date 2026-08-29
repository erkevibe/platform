# Форк lsFusion для ZUP KZ

Этот репозиторий основан на официальной платформе
[lsFusion](https://github.com/lsfusion/platform). Его задача — сохранять минимальный,
проверяемый набор платформенных расширений для казахстанских решений и регулярно
получать изменения из upstream без переписывания истории.

Бизнес-приложение ZUP KZ не следует размещать внутри ядра платформы. Рекомендуемая
структура рабочего каталога:

```text
lsfusion-kz/
├── platform-fork/       # этот репозиторий; только необходимые изменения платформы
├── zup-kz-app/          # отдельный репозиторий приложения на языке lsFusion
└── deployment/          # compose/Helm/Ansible и конфигурация окружений
```

Будущий `zup-kz-app` будет содержать независимые модули `Core`, `HR`, `Time`,
`Payroll`, `TaxesKZ`, `ReportsKZ`, `Integrations` и `Security`. Ставки и правила
будут версионироваться по периоду действия в приложении, а не зашиваться в Java-код
платформы. Каталог [`kz-extension`](kz-extension/README.md) зарезервирован только
для тех расширений платформы, которые невозможно реализовать декларативно.

## Однократная настройка форка

1. Создайте fork `lsfusion/platform` в своей GitHub-организации.
2. Клонируйте свой fork и настройте remotes:

   ```bash
   git clone git@github.com:YOUR_ORG/platform.git platform-fork
   cd platform-fork
   git remote add upstream https://github.com/lsfusion/platform.git
   git remote set-url --push upstream DISABLED
   git fetch --all --prune --tags
   git switch master
   git branch --set-upstream-to=upstream/master master
   git switch -c develop
   git push origin master
   git push -u origin develop
   ```

   Если репозиторий был клонирован прямо из официального upstream, достаточно:

   ```bash
   git remote rename origin upstream
   git remote set-url --push upstream DISABLED
   git remote add origin git@github.com:YOUR_ORG/platform.git
   git fetch --all --prune --tags
   git branch --set-upstream-to=upstream/master master
   git push origin master
   git push -u origin develop
   ```

3. Проверьте результат: `git remote -v` должен показывать GitHub fork как `origin`,
   официальный репозиторий как fetch URL `upstream`, а push URL upstream —
   `DISABLED`.

## Ветки

- `master` — локальное зеркало `upstream/master`. Собственные коммиты сюда не
  добавляются; обновление только fast-forward.
- `develop` — интеграционная ветка форка. В неё периодически вливается `master`.
- `feature/<ticket>-<name>` — короткоживущие ветки от `develop`.
- `release/<version>` — только при необходимости стабилизации релиза.
- `hotfix/<ticket>-<name>` — исправления выпущенной версии с последующим возвратом
  в `develop`.

Защитите `master` и `develop` в GitHub: запретите force push, потребуйте pull
request и успешный workflow `Fork compatibility`.

## Синхронизация с upstream

Перед обновлением рабочее дерево должно быть чистым. На Linux/macOS/Git Bash:

```bash
./scripts/sync-upstream.sh
```

В PowerShell:

```powershell
./scripts/sync-upstream.ps1
```

Скрипт выполняет `fetch --prune --tags`, fast-forward ветки `master` до
`upstream/master`, затем обычный merge `master` в `develop`. Он намеренно ничего
не отправляет на сервер. После локальной проверки опубликуйте ветки явно:

```bash
git push origin master
git push origin develop
```

Для общей ветки `develop` предпочтителен merge: он не переписывает уже
опубликованную историю и оставляет видимой точку обновления. Неопубликованную
`feature/*` перед pull request можно обновить линейно:

```bash
git fetch origin
git rebase origin/develop
```

Если возник конфликт, скрипт остановится внутри merge. Разрешите конфликт,
запустите целевые тесты и выполните `git commit`; для отмены используйте
`git merge --abort`. Не смешивайте разрешение upstream-конфликтов с новой
функциональностью в одном коммите.

## Как уменьшать конфликты

1. Не форматируйте и не перемещайте upstream-файлы без функциональной причины.
2. Сначала ищите точку расширения или отдельный модуль; патч ядра — последний
   вариант.
3. Каждый платформенный патч должен иметь тест и запись о причине, по которой его
   нельзя реализовать в `zup-kz-app`.
4. Синхронизируйтесь часто небольшими порциями.
5. Не cherry-pick одинакового исправления в несколько общих веток: используйте
   последовательный merge вперёд.

`git subtree` для всей платформы не рекомендуется: он теряет простоту сравнения с
upstream и создаёт крупные синтетические коммиты. Subtree уместен только для
независимого внешнего модуля с собственным жизненным циклом. Для ядра сохраняется
обычная upstream-история, а обновление автоматизируется скриптами.

## Проверка после обновления

Workflow [`.github/workflows/fork-compatibility.yml`](.github/workflows/fork-compatibility.yml)
еженедельно и по ручному запуску пробует слить актуальный `upstream/master` в
текущую ветку, затем собирает сервер и его зависимости на Java 21. Он также
работает для pull request и push в `develop`.

Рекомендуемый обязательный набор CI по мере развития форка:

- Maven build: `mvn -B -ntp -pl server -am clean install -DskipTests`;
- модульные тесты изменённых `api`/`server` модулей с явно включёнными тестами;
- smoke test BLB + PostgreSQL на небольшом тестовом приложении;
- сборка web-client при изменениях в `web-client`, API или протоколе;
- отдельная сборка `zup-kz-app` против артефактов обновлённой платформы;
- отчёт о различиях `git log upstream/master..develop` и зависимостях.

Плановое обновление лучше оформлять отдельным pull request вида
`chore/upstream-YYYY-MM-DD`, чтобы результат сборки, миграционные замечания и
разрешённые конфликты были видны до попадания в `develop`.

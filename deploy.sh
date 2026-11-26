#!/usr/bin/env bash
# Publica o site PSITEC no servidor (psi-tec.com) via rsync sobre SSH.
#
# Uso:
#   ./deploy.sh            # publica
#   ./deploy.sh --dry-run  # mostra o que seria enviado, sem alterar nada
#
# Autenticação: usa sua chave SSH, se estiver instalada no servidor;
# senão, o ssh pede a senha. Para instalar a chave uma única vez:
#   ssh-copy-id -p 22022 root@143.95.185.254
#
# As variáveis abaixo podem ser sobrescritas pelo ambiente, ex.:
#   DEPLOY_USER=outro ./deploy.sh
set -euo pipefail

DEPLOY_HOST="${DEPLOY_HOST:-143.95.185.254}"
DEPLOY_PORT="${DEPLOY_PORT:-22022}"
DEPLOY_USER="${DEPLOY_USER:-root}"
DEPLOY_PATH="${DEPLOY_PATH:-/home/psi-tec.com/public_html}"
SITE_OWNER="${SITE_OWNER:-psite9994:psite9994}"

cd "$(dirname "$0")"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN="--dry-run"
  echo ">> Modo simulação: nada será alterado no servidor."
fi

if [[ -n "$(git status --porcelain -- . ':!.DS_Store' 2>/dev/null)" ]]; then
  echo ">> Aviso: há alterações não commitadas; elas também serão publicadas."
fi

SSH="ssh -p $DEPLOY_PORT"
TARGET="$DEPLOY_USER@$DEPLOY_HOST"

# Uma única conexão SSH é reaproveitada pelos comandos seguintes,
# assim a senha (se houver) é pedida só uma vez.
CTRL="${TMPDIR:-/tmp}/psitec-deploy-$$"
SSH="$SSH -o ControlMaster=auto -o ControlPath=$CTRL -o ControlPersist=60"
trap '$SSH -O exit "$TARGET" >/dev/null 2>&1 || true' EXIT

echo ">> Enviando arquivos para $TARGET:$DEPLOY_PATH"
rsync -rltvz --delete $DRY_RUN \
  --exclude '.git/' \
  --exclude '.github/' \
  --exclude '.DS_Store' \
  --exclude '.claude/' \
  --exclude 'deploy.sh' \
  --exclude 'README*' \
  --exclude '.well-known/' \
  --exclude '.htaccess' \
  -e "$SSH" \
  ./ "$TARGET:$DEPLOY_PATH/"

if [[ -z "$DRY_RUN" ]]; then
  echo ">> Ajustando dono e permissões"
  # A própria pasta public_html (dono psite9994, grupo nobody, 750) não é
  # alterada: o servidor web depende desse grupo para ler o site.
  $SSH "$TARGET" "find '$DEPLOY_PATH' -mindepth 1 -exec chown $SITE_OWNER {} + \
    && find '$DEPLOY_PATH' -mindepth 1 -type d -exec chmod 755 {} + \
    && find '$DEPLOY_PATH' -mindepth 1 -type f -exec chmod 644 {} +"

  echo ">> Verificando o site"
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "https://psi-tec.com/?deploy=$(date +%s)")
  echo ">> https://psi-tec.com respondeu HTTP $code"
  [[ "$code" == "200" ]] || exit 1
fi

echo ">> Pronto."

#!/bin/bash
# Testa a proteção do Kit do Paulo com comandos de exemplo, com o jq e sem ele.
# Uso: bash testes/testar-protecao.sh        (sai 0 quando tudo passa)
# GANCHO=<arquivo> troca o gancho testado (usado para provar que o teste pega um gancho quebrado).
set -u
AQUI=$(cd "$(dirname "$0")/.." && pwd)
GANCHO=${GANCHO:-"$AQUI/plugins/kit-do-paulo/hooks/barrar-perigoso.sh"}
BASH_BIN=$(command -v bash)

BARRAR=(
  'rm -rf build'
  'rm -fr build'
  'rm -Rf node_modules'
  'rm -rfv /tmp/teste'
  'rm -r -f pasta'
  'rm -f -r pasta'
  'rm --recursive --force pasta'
  'sudo rm -rf /'
  '/bin/rm -rf pasta'
  'cd app && rm -rf dist'
  'find . -name "*.log" -delete'
  'find . -type f -exec rm {} \;'
  'python3 -c "import shutil; shutil.rmtree(\"dist\")"'
  'npx rimraf dist'
  'git push --force'
  'git push -f origin main'
  'git push origin main --force-with-lease'
  'git push origin +main'
  'git reset --hard HEAD~1'
  'git clean -fd'
  'git checkout .'
  'git checkout -- .'
  'git restore .'
  'git stash drop'
  'git branch -D velha'
  'psql -c "DROP TABLE users;"'
  'mysql -e "drop database loja"'
  'psql -c "TRUNCATE pedidos"'
  'psql -c "DELETE FROM sessions;"'
  'php artisan migrate:fresh --seed'
  'npx prisma migrate reset'
  'supabase db reset'
  'dropdb loja'
  'docker compose down -v'
  'docker volume prune'
  'docker system prune -a --volumes'
  'dd if=/dev/zero of=/dev/sda'
  'mkfs.ext4 /dev/sdb1'
  $'echo ok\nrm -rf build'
  $'git push origin main \\\n  --force'
)
DEIXAR=(
  'ls -la'
  'npm run test'
  'rm arquivo.txt'
  'rm -r pasta'
  'rm -i arquivo-rf.txt'
  'git status'
  'git push origin main'
  'git push -u origin feat/nova'
  'git push --follow-tags'
  'git reset HEAD arquivo.ts'
  'git reset --soft HEAD~1'
  'git clean -n'
  'git checkout main'
  'git checkout -b nova'
  'git checkout ./src/app.ts'
  'git restore src/app.ts'
  'git branch -d velha'
  'git commit -m "corrige o login"'
  'psql -c "DELETE FROM sessions WHERE id = 1;"'
  'psql -c "SELECT * FROM users"'
  'php artisan migrate'
  'npx prisma migrate dev'
  'docker compose down'
  'docker compose up -d'
  'docker volume ls'
  'find . -name "*.ts"'
  'grep -rf padroes.txt .'
  'truncate -s 0 app.log'
  'firmware --force'
  'echo platform -rf'
)

# Pedido do Claude Code em JSON, como chega ao gancho.
json() {
  local c=$1
  c=${c//\\/\\\\}
  c=${c//\"/\\\"}
  c=${c//$'\n'/\\n}
  c=${c//$'\t'/\\t}
  printf '{"tool_name":"Bash","tool_input":{"command":"%s","description":"teste"}}' "$c"
}

# Uma pasta com só o que o gancho usa, sem o jq, para testar o caminho sem ele.
SEM_JQ=$(mktemp -d)
for p in cat grep sed tr; do ln -s "$(command -v "$p")" "$SEM_JQ/$p"; done
limpar() { rm -f "$SEM_JQ"/cat "$SEM_JQ"/grep "$SEM_JQ"/sed "$SEM_JQ"/tr; rmdir "$SEM_JQ"; }
trap limpar EXIT

rodar() { # modo comando -> barrou | deixou | estranho
  local saida
  if [ "$1" = com-jq ]; then
    saida=$(json "$2" | "$BASH_BIN" "$GANCHO")
  else
    saida=$(json "$2" | env -i PATH="$SEM_JQ" "$BASH_BIN" "$GANCHO")
  fi
  if [ -z "$saida" ]; then echo deixou
  elif printf '%s' "$saida" | grep -q '"permissionDecision":"deny"'; then
    if command -v jq >/dev/null 2>&1 && ! printf '%s' "$saida" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
      echo estranho
    else
      echo barrou
    fi
  else echo estranho
  fi
}

modos="sem-jq"
command -v jq >/dev/null 2>&1 && modos="com-jq sem-jq" || echo "aviso: sem o jq nesta máquina, testando só o caminho sem ele"
falhas=0
total=0
for modo in $modos; do
  for c in "${BARRAR[@]}"; do
    total=$((total + 1))
    r=$(rodar "$modo" "$c")
    [ "$r" = barrou ] || { falhas=$((falhas + 1)); echo "FALHOU ($modo): devia barrar, $r: $c"; }
  done
  for c in "${DEIXAR[@]}"; do
    total=$((total + 1))
    r=$(rodar "$modo" "$c")
    [ "$r" = deixou ] || { falhas=$((falhas + 1)); echo "FALHOU ($modo): devia deixar, $r: $c"; }
  done
done

if [ "$falhas" -gt 0 ]; then
  echo "proteção: $falhas de $total casos falharam"
  exit 1
fi
echo "proteção: $total casos ok (${#BARRAR[@]} barrados e ${#DEIXAR[@]} liberados por modo: $modos)"

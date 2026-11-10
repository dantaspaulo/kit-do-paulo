#!/bin/bash
# Kit do Paulo: proteção contra comando destrutivo (gancho PreToolUse do Claude Code).
#
# O Claude Code manda o pedido em JSON pela entrada. Se o comando apaga em massa, força o envio ao GitHub,
# descarta trabalho ou apaga banco de dados, o gancho recusa e explica o motivo. Os outros comandos seguem para
# as permissões de sempre. Funciona com ou sem o jq: sem ele, procura no pedido inteiro.

entrada=$(cat)
if command -v jq >/dev/null 2>&1; then
  comando=$(printf '%s' "$entrada" | jq -r '.tool_input.command // empty' 2>/dev/null) || comando=$entrada
else
  # Sem o jq: o pedido cru, com as quebras de linha escapadas (\n, \t) trocadas por espaço.
  comando=$(printf '%s' "$entrada" | sed 's/\\[nrt]/ /g')
fi
comando=$(printf '%s' "$comando" | tr '\n\t' '  ')

barrar() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Kit do Paulo barrou: %s. Não tente outro jeito: diga à pessoa o comando e o motivo, e ela roda no terminal se for mesmo o caso."}}\n' "$1"
  exit 0
}
casa() { printf '%s' "$comando" | grep -Eq -- "$1"; }     # diferencia maiúsculas
casa_i() { printf '%s' "$comando" | grep -Eiq -- "$1"; }  # não diferencia (SQL)

INICIO='(^|[^[:alnum:]_.-])'      # começo do nome do programa: "rm" e não "firm"
ATE='[^;|&]*'                     # dentro do mesmo comando (não passa de ; | &)
FIM="([[:space:]\"=\\\\]|\$)"     # fim da opção: espaço, aspas, igual, barra ou fim do texto

casa "${INICIO}rm[[:space:]](${ATE}[[:space:]])?(-[[:alnum:]]*([rR][[:alnum:]]*f|f[[:alnum:]]*[rR])|(-[rR]|--recursive)[[:space:]]${ATE}(-f|--force)${FIM}|(-f|--force)[[:space:]]${ATE}(-[rR]|--recursive)${FIM})" && barrar "apaga uma pasta inteira sem perguntar (rm -rf)"
casa "${INICIO}find[[:space:]]${ATE}[[:space:]](-delete|-exec[[:space:]]+rm[[:space:]])" && barrar "apaga arquivos em massa (find -delete)"
casa "(shutil\.rmtree|rimraf|fs\.rmSync|Remove-Item${ATE}-Recurse)" && barrar "apaga uma pasta inteira por programa"
casa "${INICIO}git[[:space:]]+push${ATE}[[:space:]]((-f|--force|--force-with-lease|--force-if-includes)${FIM}|[+][[:alnum:]_./-]+)" && barrar "força o envio ao GitHub e pode apagar o trabalho de outra pessoa (git push --force)"
casa "${INICIO}git[[:space:]]+reset${ATE}[[:space:]]--hard" && barrar "descarta o trabalho que não foi salvo (git reset --hard)"
casa "${INICIO}git[[:space:]]+clean${ATE}[[:space:]]-[[:alnum:]]*f" && barrar "apaga os arquivos que estão fora do git (git clean -f)"
casa "${INICIO}git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.${FIM}" && barrar "descarta todas as mudanças da pasta (git checkout .)"
casa "${INICIO}git[[:space:]]+stash[[:space:]]+(drop|clear)" && barrar "apaga o trabalho guardado (git stash drop)"
casa "${INICIO}git[[:space:]]+branch${ATE}[[:space:]](-D|--delete[[:space:]]+--force)${FIM}" && barrar "apaga um branch com trabalho que não foi juntado (git branch -D)"
casa_i "(drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+(table[[:space:]]+)?[[:alnum:]_\"]|delete[[:space:]]+from[[:space:]]+[[:alnum:]_.\"]+[[:space:]]*(;|\"|'|\\\\|\$))" && barrar "apaga dados do banco (drop, truncate ou delete sem where)"
casa "(migrate:fresh|migrate:reset|db:drop|db:reset|prisma[[:space:]]+migrate[[:space:]]+reset|supabase[[:space:]]+db[[:space:]]+reset|${INICIO}dropdb[[:space:]])" && barrar "zera o banco de dados"
casa "${INICIO}docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune${ATE}--volumes|compose${ATE}[[:space:]]down${ATE}[[:space:]](-v|--volumes)${FIM})" && barrar "apaga os dados guardados no Docker"
casa "(${INICIO}mkfs|${INICIO}dd[[:space:]]${ATE}of=/dev/|diskutil[[:space:]]+(erase|zero|secureErase))" && barrar "apaga um disco"
exit 0

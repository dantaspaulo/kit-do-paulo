# Kit do Paulo para o Claude Code

Pacotes (plugins) do Claude Code em português, para quem está começando e para quem quer trabalhar com mais
segurança. Feito por Paulo Sérgio Dantas, da PSD Software.

| Pacote | O que instala |
|---|---|
| `kit-do-paulo` | A proteção contra comando destrutivo, um revisor de código e a skill de revisar commit |
| `comece-por-aqui` | O `kit-do-paulo` e mais 7 plugins oficiais, de uma vez |

## Instalar

No terminal:

```bash
claude plugin marketplace add dantaspaulo/kit-do-paulo
claude plugin install kit-do-paulo@kit-do-paulo
```

Ou o pacote completo, que já inclui o de cima:

```bash
claude plugin marketplace add dantaspaulo/kit-do-paulo
claude plugin install comece-por-aqui@kit-do-paulo
```

Dentro do Claude Code, o mesmo com barra: `/plugin marketplace add dantaspaulo/kit-do-paulo` e
`/plugin install kit-do-paulo@kit-do-paulo`. Numa sessão que já estava aberta, rode `/reload-plugins` depois.

Para conferir: `claude plugin list`.

## O que vem no `kit-do-paulo`

**Proteção contra comando destrutivo.** Antes de o Claude rodar um comando no terminal, o kit recusa o que:

- apaga em massa: `rm -rf`, `find -delete`, `shutil.rmtree`, `rimraf`;
- força o envio ao GitHub e pode apagar o trabalho de outra pessoa: `git push --force`;
- descarta trabalho: `git reset --hard`, `git checkout .`, `git restore .`, `git clean -f`, `git stash drop`,
  `git branch -D`;
- apaga dados de banco: `DROP TABLE`, `TRUNCATE`, `DELETE` sem `WHERE`, `migrate:fresh`, `prisma migrate reset`,
  `supabase db reset`, `docker compose down -v`;
- apaga um disco: `mkfs`, `dd ... of=/dev/...`.

O Claude explica o motivo e não tenta outro caminho; se for mesmo o caso, você roda o comando no terminal. Os outros
comandos seguem para as permissões de sempre. Funciona com ou sem o `jq`. No Windows, precisa do Git Bash (vem com o
Git para Windows).

**Revisor** (`kit-do-paulo:revisor`). Um subagente que lê o que mudou e aponta, nesta ordem, segurança, bugs, falta
de teste e clareza. Não edita arquivo nenhum. Peça: "use o revisor no que eu mudei".

**Revisar commit** (`/kit-do-paulo:revisar-commit`). Confere o que vai entrar no commit, procura segredo (chave,
token, senha, `.env`), olha os testes, escreve a mensagem no padrão Conventional Commits e espera o seu ok. O Claude
também chama sozinho quando você pede para commitar.

## O que vem no `comece-por-aqui`

O `kit-do-paulo` e estes 7 plugins da loja oficial (`claude-plugins-official`), que o Claude Code já traz
registrada:

| Plugin | Para quê |
|---|---|
| `learning-output-style` | Modo aprendiz: o Claude explica e deixa você escrever as partes principais |
| `claude-md-management` | Mantém o CLAUDE.md do projeto em dia |
| `mattpocock-skills` | Skills de planejamento, TDD e revisão de código |
| `context7` | Documentação atual das bibliotecas, na hora |
| `playwright` | O Claude abre o navegador, clica e confere a tela |
| `security-guidance` | Avisa de risco de segurança enquanto o código é escrito e antes do commit |
| `skill-creator` | Ajuda a criar a sua própria skill |

## Atualizar e remover

```bash
claude plugin marketplace update kit-do-paulo
claude plugin update kit-do-paulo@kit-do-paulo
claude plugin uninstall kit-do-paulo@kit-do-paulo
```

## Testar a proteção

```bash
bash testes/testar-protecao.sh
```

São 70 comandos de exemplo, 40 que devem ser barrados e 30 que devem passar, rodados com o `jq` e sem ele.

## Licença

MIT. Veja o arquivo `LICENSE`.

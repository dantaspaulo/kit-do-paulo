---
name: revisar-commit
description: Revisa o que vai entrar num commit e escreve a mensagem. Use quando a pessoa pedir para commitar, revisar commit ou preparar um pull request.
---

# Revisar commit

1. Rode `git status` e `git diff --staged` e leia tudo o que vai entrar. Se nada estiver preparado, mostre o `git diff` e pergunte o que entra.
2. Procure segredo (chave, token, senha, .env) e arquivo que não devia ir. Achou: pare e avise.
3. Confira se o que mudou tem teste e se os testes passam.
4. Escreva a mensagem no padrão Conventional Commits (feat:, fix:, docs:), com título de até 72 caracteres.
5. Mostre a mensagem e espere o ok da pessoa antes de commitar.

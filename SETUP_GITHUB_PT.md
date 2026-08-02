# Publicar o ICARUS na conta MmmPT

O pacote está preparado para o repositório público:

```text
https://github.com/MmmPT/icarus-zx-spectrum
```

A página ficará em:

```text
https://mmmpt.github.io/icarus-zx-spectrum/
```

## 1. Criar o repositório

1. Entra na conta `MmmPT` no GitHub.
2. Cria um novo repositório chamado exatamente `icarus-zx-spectrum`.
3. Escolhe **Public**.
4. Não adiciones README, licença ou `.gitignore`, porque já estão neste pacote.

## 2. Enviar os ficheiros

Descompacta este pacote e, numa linha de comandos aberta dentro da pasta, executa:

```bash
git init
git branch -M main
git add .
git commit -m "Initial ICARUS release"
git remote add origin https://github.com/MmmPT/icarus-zx-spectrum.git
git push -u origin main
```

Também podes usar o GitHub Desktop e escolher **Add an Existing Repository from your Local Drive**.

## 3. Ativar o GitHub Pages

No repositório:

1. Abre **Settings**.
2. Escolhe **Pages**.
3. Em **Build and deployment**, seleciona **Deploy from a branch**.
4. Escolhe a branch `main` e a pasta `/docs`.
5. Guarda.

O ficheiro de entrada já está em `docs/index.html`.

## 4. Criar a versão v1.0

1. Abre **Releases** no repositório.
2. Escolhe **Create a new release**.
3. Cria a tag `v1.0`.
4. Usa o título `ICARUS v1.0`.
5. Copia o texto de `RELEASE_NOTES_v1.0.md`.
6. Anexa `release/Icarus_ZX_Spectrum_v1.0.zip`.
7. Publica a release.

## Ficheiros deliberadamente excluídos

- `48.rom`
- `boot_mem.pkl`

A ROM do ZX Spectrum não deve ser distribuída neste repositório.

#💥

#opção A — PowerShell (Windows)
# Converte .withOpacity(x) -> .withValues(alpha: x) em todos os .dart do projeto
# Faz backup .bak antes de cada alteração

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$project = Resolve-Path (Join-Path $root "..")

# 1) listar todos os .dart
$files = Get-ChildItem -Path $project -Recurse -Include *.dart -File

# 2) regex que apanha QUALQUER coisa dentro de withOpacity(...)
#    ex: .withOpacity(.4), .withOpacity(0.4), .withOpacity(opacidadeVar)
$pattern = '\.withOpacity\(\s*(.*?)\s*\)'

$changed = 0
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw
  if ($text -match $pattern) {
    # backup
    Copy-Item -Path $f.FullName -Destination ($f.FullName + ".bak") -Force
    # replace
    $newText = [Regex]::Replace($text, $pattern, '.withValues(alpha: $1)')
    Set-Content -LiteralPath $f.FullName -Value $newText -Encoding UTF8
    $changed += 1
    Write-Host "✔ Alterado:" $f.FullName
  }
}

if ($changed -eq 0) {
  Write-Host "Nenhuma ocorrência encontrada." -ForegroundColor Yellow
} else {
  Write-Host "`n$changed ficheiro(s) atualizados." -ForegroundColor Green
  Write-Host "Backups criados com extensão .bak"
}


# opção B — substituição rápida no VS Code
abre Search (Ctrl+Shift+F)

ativa Use Regular Expression (.*)
Find:
\.withOpacity\(\s*(.*?)\s*\)

Replace:
.withValues(alpha: $1)

scope: a pasta do projeto
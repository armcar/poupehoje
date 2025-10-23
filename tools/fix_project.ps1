# ===============================
# 🧹 Flutter / Dart Project Fixer
# ===============================
# Corrige problemas de lint, formata código e aplica fixes automáticos
# Local: tools/fix_project.ps1
# .\tools\fix_project.ps1


Write-Host "🔍 Analisando código Flutter/Dart..." -ForegroundColor Cyan
dart analyze

Write-Host "`n🛠️  Aplicando correções automáticas..." -ForegroundColor Yellow
dart fix --apply

Write-Host "`n🎨 Formatando código..." -ForegroundColor Green
dart format .

Write-Host "`n✅ Tudo pronto! O codigo foi limpo e formatado corretamente." -ForegroundColor Green


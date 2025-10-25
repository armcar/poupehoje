@echo off
setlocal enabledelayedexpansion

:: ===============================
:: Script: publish_release.bat
:: Autor: ArmCar & GPT
:: Objetivo: Automatizar release da branch dev → main
:: ===============================

echo.
echo 🚀 Publicar nova release do Poupe Hoje
echo ===============================

:: 1️⃣ Perguntar a versão
set /p VERSION=Digite o número da versão (ex: 1.0.0): 

:: 2️⃣ Fazer commit das alterações na dev
echo.
echo 💾 A guardar alterações na DEV...
git add .
git commit -m "Versão %VERSION% — atualização automática"
git push origin dev

:: 3️⃣ Mudar para a MAIN
echo.
echo 🔄 A mudar para MAIN...
git checkout main

:: 4️⃣ Atualizar a MAIN com a DEV
echo.
echo 🔀 A fazer merge da DEV → MAIN...
git merge dev

:: 5️⃣ Enviar MAIN para o GitHub
git push origin main

:: 6️⃣ Criar e enviar TAG da versão
echo.
echo 🏷️  A criar tag v%VERSION%...
git tag -a v%VERSION% -m "Versão %VERSION% — release estável"
git push origin v%VERSION%

:: 7️⃣ Voltar para a DEV
echo.
echo 🔁 A voltar para DEV...
git checkout dev

echo.
echo ✅ Publicação concluída com sucesso!
echo Branch main e tag v%VERSION% enviadas para o GitHub.
echo ===============================
pause

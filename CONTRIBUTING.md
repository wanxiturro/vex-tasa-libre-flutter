# ¿Cómo contribuir a Vex?

1. Haz **fork** del repositorio
2. Crea una rama descriptiva: `git checkout -b fix/mi-cambio`
3. Haz tus cambios y commitea: `git commit -m "Descripción del cambio"`
4. Push: `git push origin fix/mi-cambio`
5. Abre un **Pull Request** hacia la rama `develop` ← nunca a `main`
6. Espera la revisión — los cambios aprobados se mergean a `main` en cada release

## ⚠️ Reglas importantes
- No hacer push directo a `main` ni a `develop`
- Un PR por funcionalidad o fix — no mezcles cambios
- Si vas a trabajar en algo grande, abre primero un **Issue** para discutirlo

## Convención de commits
- — Commit inicial
- — Nueva funcionalidad
- — Fix de bug
- — UI/estilos
- — Documentación
- — Mejora de rendimiento
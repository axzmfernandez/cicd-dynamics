# CICDDynamics

Repositorio de prueba técnica para desplegar soluciones de Dynamics 365 / Power Platform entre entornos (DEV, QA, PROD) con GitHub Actions.

- **Publisher:** `axz` (prefijo de todos los componentes, por ejemplo `axz_solicitud`).
- **Solución inicial:** `AXZ_Core`.
- **Plugin:** `plugins/Axz.Plugins` (.NET Framework 4.6.2, firmado con strong name).

## Estructura

```
.github/workflows/   export-from-dev, ci, cd
config/              deployment settings por entorno (qa.json, prod.json)
plugins/Axz.Plugins/ plugin de ejemplo (PreOperation / Create sobre axz_solicitud)
solutions/           soluciones desempaquetadas (AXZ_Core/src tras el primer export)
```

## Puesta en marcha

1. En DEV, crea el publisher con prefijo `axz` y la solución `AXZ_Core` (tabla `axz_solicitud` con `axz_correlationid` y `axz_estado`, variable de entorno `axz_apimbaseurl`).
2. La clave de firma del plugin ya está en `plugins/Axz.Plugins/axazure.snk` (RSA 2048). Dataverse exige ensamblado firmado.
3. En GitHub, crea tres environments (`dev`, `qa`, `prod`). En `prod`, activa *Required reviewers*.
4. En cada environment, define los secrets `ENV_URL`, `TENANT_ID`, `CLIENT_ID` y `CLIENT_SECRET` (app registration dada de alta como application user en ese entorno).
5. Registra el plugin en DEV con `pac tool prt` y añade el ensamblado y el paso a la solución.
6. Lanza el workflow **export-from-dev**: exporta unmanaged y managed, desempaqueta en modo `Both` y abre una PR.
7. Al integrar la PR en `main`, **cd** compila, empaqueta como managed, despliega en QA y espera aprobación para PROD.

## Scripts

```
pwsh scripts/build-plugin.ps1                       # compila y comprueba la firma
pwsh scripts/build-plugin.ps1 -Solution AXZ_Core    # además copia la DLL a la solución desempaquetada
pwsh scripts/publish-plugin.ps1 -PluginId <guid>    # compila y publica en el entorno activo de pac
pwsh scripts/publish-plugin.ps1 -PluginId <guid> -EnvironmentUrl https://<org>.crm4.dynamics.com
```

`publish-plugin.ps1` actualiza un ensamblado ya registrado (`pac plugin push`). El primer registro se hace una vez con `pac tool prt`; el `PluginId` es el `pluginassemblyid` de ese ensamblado.

## Notas

- Mantén `AssemblyVersion` en `1.0.0.0`; la versión de cada build va en `FileVersion`.
- El empaquetado managed requiere que la solución se haya desempaquetado con `solution-type: Both`.
- Los nombres de parámetros de `microsoft/powerplatform-actions` pueden variar según la versión: comprueba cada acción antes del primer despliegue.
- Pendiente: proyecto de tests del plugin y paso `dotnet test` en los workflows.

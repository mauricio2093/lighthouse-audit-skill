# Solución de Lighthouse en WSL usando Google Chrome Stable

## Objetivo

Permitir que `lighthouse` se ejecute correctamente dentro de WSL cuando falla al lanzar el navegador automáticamente o cuando aparece un error de conexión como `ECONNREFUSED`.

## Contexto del problema

En este entorno, Lighthouse no estaba funcionando correctamente usando la detección automática del navegador o una ruta distinta de Chrome.

La solución confirmada fue indicar manualmente la ruta de **Google Chrome Stable** mediante la variable de entorno `CHROME_PATH`.

## Síntomas típicos

- Error similar a:

```text
LH:ChromeLauncher:error connect ECONNREFUSED 127.0.0.1:XXXXX
```

- Lighthouse no logra abrir Chrome dentro de WSL.
- Chromium puede no estar disponible, no ser compatible, o no estar siendo detectado correctamente.

## Procedimiento correcto

### 1. Exportar la ruta de Chrome Stable

Verifcar primero si ya existe una ruta establecida:  

```bash
echo $CHROME_PATH
ls -l "$CHROME_PATH"
```

Resultado esperado aproximado:

```bash
/usr/bin/google-chrome-stable
lrwxrwxrwx 1 root root ... /usr/bin/google-chrome-stable -> /opt/google/chrome/google-chrome
```

En caso contrario exportar la ruta de Google Chrome Stable:

```bash
export CHROME_PATH=/usr/bin/google-chrome-stable
```

### 2. Verificar que la ruta exista

```bash
echo $CHROME_PATH
ls -l "$CHROME_PATH"
```

Resultado esperado aproximado:

```bash
/usr/bin/google-chrome-stable
lrwxrwxrwx 1 root root ... /usr/bin/google-chrome-stable -> /opt/google/chrome/google-chrome
```

### 3. Ejecutar Lighthouse con flags compatibles con WSL

```bash
lighthouse https://dominio.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

## Solución validada

La combinación que sí funcionó fue:

```bash
export CHROME_PATH=/usr/bin/google-chrome-stable
lighthouse https://dominio.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

## Cómo debe razonar una IA ante este problema

Si Lighthouse falla en WSL, la IA debe proceder así:

1. **Identificar que el problema probablemente está en el navegador**, no necesariamente en Lighthouse.
2. **Verificar si existe Google Chrome Stable** en la ruta:

   ```bash
   /usr/bin/google-chrome-stable
   ```

3. **Configurar `CHROME_PATH` manualmente** antes de volver a ejecutar Lighthouse.
4. **Usar flags apropiados para entornos WSL/headless**:
   - `--headless`
   - `--no-sandbox`
   - `--disable-gpu`
5. **No asumir que Chromium funcionará igual que Chrome Stable**.
6. **Confirmar el éxito solo si Lighthouse genera el reporte** (`.html`, `.json` o salida completa sin error de launcher`).

## Reglas prácticas para futuras respuestas

- No insistir primero en reinstalar Lighthouse si el error principal es del navegador.
- Priorizar la verificación de `CHROME_PATH`.
- En WSL, sugerir Google Chrome Stable antes que soluciones genéricas.
- Si aparece `ECONNREFUSED`, considerar que Chrome no logró iniciar correctamente.
- Usar siempre una prueba real con una URL para validar la solución.

## Solución permanente opcional

Para no tener que ejecutar `export CHROME_PATH=...` en cada sesión, agregar esto al final de `~/.bashrc`:

```bash
export CHROME_PATH=/usr/bin/google-chrome-stable
```

Luego recargar:

```bash
source ~/.bashrc
```

## Checklist de diagnóstico

```bash
echo $CHROME_PATH
ls -l "$CHROME_PATH"
which lighthouse
lighthouse https://dominio.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

## Resultado esperado

- Lighthouse se ejecuta sin error de conexión al launcher.
- Se genera el reporte correctamente.
- WSL usa Google Chrome Stable como navegador para la auditoría.

## Resumen corto para IA
>
> Si Lighthouse falla en WSL con errores de conexión o lanzamiento del navegador, configurar manualmente `CHROME_PATH=/usr/bin/google-chrome-stable` y ejecutar Lighthouse con `--headless --no-sandbox --disable-gpu`.

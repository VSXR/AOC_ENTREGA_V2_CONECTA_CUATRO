; ============================================================================================
; ARCHIVO: ConnectFour.asm
; USO: Archivo principal y punto de entrada (entry point) del juego "Conecta 4".
;      Define la configuración del ensamblador Z80, inicializa la CPU,
;      la pila (stack) y transfiere el control a la pantalla de inicio.
; ============================================================================================

    DEVICE ZXSPECTRUM48
	SLDOPT COMMENT WPMEM, LOGPOINT, ASSETION
    ORG $8000

; ============================================================================================
; PUNTO DE ENTRADA E INICIALIZACIÓN
; ============================================================================================
BEGIN:
    DI
    LD SP, $FFFF        ; Inicializamos la pila al final de la memoria para no chocar con la direccion ORG $8000 (por si acaso)

    CALL CLEARSCR
    JP START_SCREEN

; ============================================================================================
; INCLUDES DEL PROYECTO (ARCHIVOS .ASM)
; ============================================================================================
; ----------------------------------------------
; 1. Datos (Variables y Constantes)
; ----------------------------------------------
    INCLUDE "data/constants.asm"
    INCLUDE "data/variables.asm"

; ----------------------------------------------
; 2. Lógica del Juego
; ----------------------------------------------
    INCLUDE "game/input.asm"
    INCLUDE "game/logic.asm"
    
; ----------------------------------------------
; 3. Gráficos (Rutinas de dibujo)
; ----------------------------------------------
    INCLUDE "graphics/fichas.asm"
    INCLUDE "graphics/portada.asm"
    INCLUDE "graphics/posxy.asm"
    INCLUDE "graphics/tablero.asm"
    INCLUDE "graphics/utils.asm"

; ----------------------------------------------
; 4. Entrada/Salida (IO)
; ----------------------------------------------
    INCLUDE "io/keyboard.asm"
    INCLUDE "io/printat.asm"

; ----------------------------------------------
; 5. Pantallas (Flujo del programa)
; ----------------------------------------------
    INCLUDE "screens/common.asm"
    INCLUDE "screens/StartScreen.asm"
    INCLUDE "screens/GameScreen.asm"
    INCLUDE "screens/EndScreen.asm"
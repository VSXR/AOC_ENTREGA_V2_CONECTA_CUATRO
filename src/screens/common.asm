; ============================================================================================
; ARCHIVO: common.asm
; USO: Lógica reutilizable para rutinas comunes del programa.
;      Incluye inicialización de pantalla, diálogos de confirmación (S/N)
;      y la pantalla de salida del juego.
; ============================================================================================

; --------------------------------------------------------------------------------------------
; COMMON_INIT_SCREEN
; Limpia la pantalla completa, pone el borde negro y establece los atributos
; de color por defecto (llamando a la rutina de borde blanco).
; --------------------------------------------------------------------------------------------
COMMON_INIT_SCREEN:
    XOR A                       ; A = 0
    OUT ($FE), A                ; Establece el color del borde a 0 (Negro)
    CALL CLEARSCR               ; Llama a la ROM para borrar el área de píxeles y atributos
    CALL COLOR_BORDE_PANTALLA   ; Restablece el borde (posiblemente a blanco, según la rutina)
    RET

; --------------------------------------------------------------------------------------------
; COMMON_HANDLE_PLAY_RESPONSE
; Gestiona la navegación estándar después de una pregunta de "Jugar".
; Esta rutina NO RETORNA. Transfiere el control (JP) a otra pantalla.
;
; ENTRADA:
;   IX = Puntero al mensaje de título (para COMMON_SHOW_CONFIRM_SCREEN)
;   IY = Puntero a la pregunta (para COMMON_SHOW_CONFIRM_SCREEN)
; --------------------------------------------------------------------------------------------
COMMON_HANDLE_PLAY_RESPONSE:
    ; 1. Mostrar la pantalla de confirmación
    CALL COMMON_SHOW_CONFIRM_SCREEN ; Espera una respuesta S/N
                                    ; Retorna A=1 (Sí) o A=0 (No)
    
    ; 2. Evaluar la respuesta
    CP 1                            ; Compara A con 1 (Sí)
    
    ; 3. Saltar a la pantalla correspondiente
    JP Z, GAME_SCREEN               ; Si A=1 (Z=1), saltar a la pantalla de juego
    JP COMMON_MESSAGE_BYE_SCREEN    ; Si A=0 (Z=0), saltar a la pantalla de despedida

; --------------------------------------------------------------------------------------------
; COMMON_SHOW_CONFIRM_SCREEN
; Muestra una interfaz estandarizada de pregunta S/N en la parte inferior
; de la pantalla y espera la entrada del usuario.
;
; ENTRADA:
;   IX = Dirección del mensaje de título (arriba). Si es 0, se omite.
;   IY = Dirección de la pregunta (abajo, ej: "¿Quieres jugar?").
;
; SALIDA:
;   A = 1 (si el usuario pulsó 'S')
;   A = 0 (si el usuario pulsó 'N')
; --------------------------------------------------------------------------------------------
COMMON_SHOW_CONFIRM_SCREEN:
    ; 1. Mostrar Título Superior (si existe)
    LD A, (IX)                  ; Carga el primer byte del puntero IX
    OR A                        ; Comprueba si A es 0 (cadena vacía)
    JR Z, .SKIP_TITLE           ; Si es 0, omitir el dibujo del título

    LD A, COLOR_AMARILLO_NEGRO  ; Atributo para el título
    LD B, 1                     ; Fila 1
    LD C, 7                     ; Columna 7
    CALL PRINTAT                ; (IX ya está cargado con el título)

.SKIP_TITLE:
    ; 2. Mostrar Pregunta Inferior (ej: "Quieres jugar?")
    LD A, COLOR_ROJO_BLANCO_FLASH ; Atributo parpadeante
    LD B, 20                    ; Fila 20
    LD C, 4                     ; Columna 4
    PUSH IX                     ; Salvar IX (título) temporalmente
    LD IX, IY                   ; Cargar IX con la pregunta (IY)
    CALL PRINTAT
    POP IX                      ; Restaurar IX

    ; 3. Mostrar prompt "(S / N):" al lado de la pregunta
    LD A, COLOR_ROJO_BLANCO_FLASH ; Mismo atributo
    LD B, 20                      ; Misma fila 20
    LD C, 20                      ; Columna 20 (más a la derecha)
    PUSH IX
    LD IX, CONFIRMATION_MESSAGE_SN ; Puntero al texto "(S / N):"
    CALL PRINTAT
    POP IX

    ; 4. Leer respuesta del usuario (Bloqueante)
    CALL KEYBOARD_LEER_SN       ; Espera hasta que se pulse 'S' o 'N'
    LD (MESSAGE_KEY_SN), A      ; Guarda el carácter ('S' o 'N') en una variable

    ; 5. Mostrar la tecla pulsada (Eco visual)
    LD A, COLOR_ROJO_BLANCO_FLASH ; Mismo atributo
    LD B, 20
    LD C, 28
    PUSH IX
    LD IX, MESSAGE_KEY_SN       ; Puntero a la variable que contiene la tecla
    CALL PRINTAT
    POP IX

    ; 6. Evaluar y preparar el valor de retorno
    LD A, (MESSAGE_KEY_SN)
    CP 'S'                      ; ¿Pulsó 'S'?
    JR Z, .RETURN_YES
    
    ; Si no fue 'S', fue 'N'
    XOR A                       ; A = 0 (No)
    RET
.RETURN_YES:
    LD A, 1                     ; A = 1 (Sí)
    RET

; --------------------------------------------------------------------------------------------
; COMMON_MESSAGE_BYE_SCREEN
; Muestra la pantalla de despedida y detiene la ejecución del programa.
; --------------------------------------------------------------------------------------------
COMMON_MESSAGE_BYE_SCREEN:
    CALL COMMON_INIT_SCREEN     ; Limpiar la pantalla
    
    ; Mostrar mensaje "Hasta pronto!"
    LD A, COLOR_ROJO_BLANCO_FLASH
    LD B, 10                    ; Fila 10
    LD C, 10                    ; Columna 10
    LD IX, BYE_MESSAGE          ; Puntero al texto de despedida
    CALL PRINTAT

    HALT                        ; Detiene la CPU. Fin del programa.
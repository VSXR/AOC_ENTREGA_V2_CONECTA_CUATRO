; ============================================================================================
; ARCHIVO: StartScreen.asm
; USO: Pantalla de bienvenida principal y punto de entrada del programa.
;      Muestra el título, el gráfico de portada y pregunta al usuario si desea jugar.
; ============================================================================================

START_SCREEN:
    ; 1. Inicialización
    ; Llama a la rutina común para limpiar la pantalla, poner el borde negro
    ; y establecer los atributos de color por defecto.
    CALL COMMON_INIT_SCREEN    

    ; --- 2. Dibujar Título "Bienvenido al Conecta 3" ---
    LD A, COLOR_AMARILLO_NEGRO  ; Atributo: Amarillo brillante sobre negro
    LD B, 1                     ; Fila (Y) = 1
    LD C, 5                     ; Columna (X) = 5
    LD IX, WELCOME_MESSAGE      ; Puntero al texto a imprimir
    CALL PRINTAT

    ; --- 3. Dibujar Gráfico de Portada ---
    ; Llama a la rutina en portada.asm para dibujar el "C4" animado.
    CALL PORTADA_DibujarPortada

    ; --- 4. Preguntar "¿Quieres jugar?" ---
    ; Carga los punteros para la rutina de confirmación S/N (COMMON_SHOW_CONFIRM_SCREEN).
    LD IX, EMPTY_MESSAGE            ; IX = Puntero al título superior (ninguno)
    LD IY, PLAY_MESSAGE_1           ; IY = Puntero a la pregunta inferior
    
    ; Esta rutina NO retornará aquí; saltará directamente a:
    ;   - GAME_SCREEN (si pulsa 'S')
    ;   - COMMON_MESSAGE_BYE_SCREEN (si pulsa 'N')
    JP COMMON_HANDLE_PLAY_RESPONSE
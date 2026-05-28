; ====================================================================================================
; ARCHIVO: posxy.asm
; USO: Rutinas de conversión de coordenadas (Y,X) a direcciones de memoria
;      de la pantalla del ZX Spectrum.
; ====================================================================================================

; ====================================================================================================
; FUNCIÓN: POSXY_CalcPixelAddr_4000
;
; DESCRIPCIÓN:
;   Calcula la dirección de memoria de PÍXELES (rango $4000 - $57FF)
;   correspondiente a una coordenada (H=Y, L=X).
;
;   La pantalla del Spectrum está dividida en 3 tercios (cuadrantes) verticales:
;    - 1er Tercio (Y: 0-7)   -> Base $4000
;    - 2do Tercio (Y: 8-15)  -> Base $4800
;    - 3er Tercio (Y: 16-23) -> Base $5000
;
; ENTRADA: H = Coordenada Y (0-23), L = Coordenada X (0-31)
; SALIDA:  HL = Dirección en memoria de vídeo ($4xxx o $5xxx)
; ====================================================================================================
POSXY_CalcPixelAddr_4000:
    PUSH AF: PUSH BC: PUSH DE             ; Preservar registros

    LD E, $40                             ; Base por defecto = $4000 (1er tercio)

    ; --- 1. Determinar en qué tercio está Y (H) ---
    LD A, 7
    CP H
    JR NC, .CALC_COMMON                   ; Si Y <= 7  -> 1er tercio (E=$40)

    LD A, 15
    CP H
    JR NC, .CALC_2DO_TERCIO               ; Si Y <= 15 -> 2do tercio

    ; --- 3er Tercio (Y: 16-23) ---
    LD A, H
    SUB 16                                ; A = H - 16 (Normalizar Y a 0-7)
    LD H, A
    LD E, $50                             ; Base = $5000
    JR .CALC_COMMON

.CALC_2DO_TERCIO:
    ; --- 2do Tercio (Y: 8-15) ---
    LD A, H
    SUB 8                                 ; A = H - 8 (Normalizar Y a 0-7)
    LD H, A
    LD E, $48                             ; Base = $4800

.CALC_COMMON:
    ; --- 2. Cálculo común de la dirección ---
    ; (H = Y normalizada 0-7, E = Base del tercio, L = X 0-31)
    
    LD A, H                               ; A = Y (0-7)
    SLA A: SLA A: SLA A: SLA A: SLA A     ; A = Y * 32 (Desplazamiento de fila)
    OR L                                  ; A = (Y * 32) + X (Desplazamiento total)
    LD L, A                               ; L = Byte bajo de la dirección

    LD A, H
    SRA A: SRA A: SRA A                   ; A = Y / 8 (Ajuste para el byte alto)
    OR E                                  ; Combinar con la Base ($40, $48 o $50)
    LD H, A                               ; H = Byte alto de la dirección

    POP DE: POP BC: POP AF
    RET

; ====================================================================================================
; FUNCIÓN: POSXY_CalcAttrAddr_5800
;
; DESCRIPCIÓN:
;   Calcula la dirección de memoria de ATRIBUTOS (rango $5800 - $5AFF)
;   correspondiente a una coordenada de carácter (H=Y, L=X).
;
;   La fórmula es: Dirección = $5800 + (Y * 32) + X
;
; ENTRADA: H = Coordenada Y (0-23), L = Coordenada X (0-31)
; SALIDA:  HL = Dirección de atributo ($58xx - $5Axx)
; ====================================================================================================
POSXY_CalcAttrAddr_5800:
    PUSH AF                              ; Preservar AF

    ; --- Cálculo del Byte Bajo (L) ---
    LD A, H                              ; A = Y
    SLA A: SLA A: SLA A: SLA A: SLA A    ; A = Y * 32 (5 desplazamientos)
    OR L                                 ; A = (Y * 32) + X
    LD L, A                              ; L = Byte bajo de la dirección

    ; --- Cálculo del Byte Alto (H) ---
    LD A, H                              ; A = Y
    SRA A: SRA A: SRA A                  ; A = Y / 8 (3 desplazamientos)
    OR $58                               ; Combinar con la base de atributos $5800
    LD H, A                              ; H = Byte alto de la dirección

    POP AF                               ; Restaurar AF
    RET
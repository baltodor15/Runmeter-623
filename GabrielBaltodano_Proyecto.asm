;******************************************************************************
;                         Universidad de Costa Rica
;                       Escuela de Ingeniería Eléctrica
;                          IE-0623 Microprocesadores
;                              Proyecto Final
;                               Run Meter 623
;Autor:Gabriel Baltodano Dormond C00906
;Profesor Geovanny Delgado.
;******************************************************************************
;El siguiente programa permite el funcionamiento adecuado de la aplicación
;runmeter 623, el cual se encarga de medir la velocidad y las vueltas que realiza
;un ciclista en un velodromo. La aplicación se implemnto mediante la tarjeta de
;desarrollo dragon 12.
;******************************************************************************
#include registers.inc
;******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;******************************************************************************
                                Org $3E66
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************
;******************************************************************************
;                           DEFINICION DE VALORES
;******************************************************************************
;---------------------------Valores Tabla Timers-------------------------------
;--- Aqui se colocan los valores de carga para los timers de la aplicacion ----
tSubRebPB:        EQU 10      ;suprecion de rebotes 10ms
tSubRebTCL:       EQU 10       ;supresion de rebotes 10ms
tShortP:          EQU 25
tLongP:           EQU 2         ;se le puso 2 por que dura mucho con 3

tTimer1mS:        EQU 50    ;Base de tiempo de 1 mS (20 us x 50)
tTimer10mS:       EQU 10    ;Base de tiempo de 10 mS (20 uS x 50)
tTimer100mS:      EQU 10    ;Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 10    ;Base de tiempo de 1 segundo (100 mS x 10)
tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos
tTimerDigito:     EQU 2     ; 2ms
tMaxCountTicks    EQU 100
tTimerBrillo      EQU 1     ; 1 x 100mS


;-----------------------Valores Acii-------------------------------------------
CR:         Equ  $0D    ; Carriage Return
LF:         Equ  $0A    ; Line Feed
EOM:        Equ  $FF    ; Final de string
BS:         Equ  $08    ; BackSpace
CP:         Equ  $1A    ; Substitute

;===============================================================================
;--------------------------- Valores de tarea PB--------------------------------
;===============================================================================
PortPB:           EQU PTIH
MaskPB:           EQU $01 ;PH0
MaskPB_2:         EQU $08 ;PH3

;--------------------------- Valores Teclado------------------------------------
;Mascaras para poder verficar cual columna se presionó en el teclaso
Mask_COL1         EQU $01
Mask_COL2         EQU $02
Mask_COL3         EQU $04
;--------------------------------- valores de tarea presPB----------------------
;Constantes para activación de banderas_1
ShortP_1:           EQU $01
LongP_1:            EQU $02
ShortP_2:         EQU $04
LongP_2:          EQU $08
ARRAY_OK:         EQU $10
;------------------Valores de banderas para SendLCD-----------------------------
;Constantes para activación de banderas_2
RS:               EQU $01
LCD_OK:           EQU $02
FinSendLCD:       EQU $04
Second_Line:      EQU $08



;------------------------------Valores de Tarea_LCD----------------------------
tTimer2mS:                       EQU 2
tTimer260uS:                     EQU 13 ; 20uS*13= 260Us
tTimer40uS:                      EQU 2  ; 20uS*2= 40uS
EOB:                             EQU $FF
ADD_L1:                          EQU $80
ADD_L2:                          EQU $C0
Clear_LCD:                       EQU $01

;--------------------------Valores Tarea Configurar----------------------------

MaxNumVueltas:                   EQU 25
MinNumVueltas:                   EQU 3
;---------------------------Valores Tarea Competencia--------------------------
tTimerVel:                       EQU 100  ; 100mS*100= 10s
tTimerError:                     EQU 3   ;1s*3
VelocMin:                        EQU 45 ;Km/h
VelocMAX:                        EQU 95 ;Km/h
;----------------------------Valores adicioneales para Calculos-----------------
Dist_S1S2:                       EQU 55   ;distancia entre S1 y S2       (Metros)
DistS2_P                         EQU 300  ;Distancia entre S2 y Pantalla (Metros)
Dist_Meta:                       EQU 200  ;Distancia entre S2 y meta     (Metros)
FactorConv:                      EQU 1980  ;Factor de conv (55*3.6Km/H)/(100mS*t)
                                          ;Convierte a Km por hora
FactorConv2:                     EQU 7200 ;1000m/3600 = 3.6m/s Factor2=200m*3.6m/s*10  =7200

FactorConv3:                     EQU $2A30  ;Factor2=300m*3.6m/s*10 = 10800 = $2A30
;******************************************************************************
;                       DEFINICION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************


;===============================================================================
;                         Estructuras Teclado matricial
;===============================================================================
                                Org $1000
MAX_TCL:          ds 1      ;Almacena valor maximo de valores que se pueden ingresar
Tecla:            ds 1      ;contieme la tecla que se presionó
Tecla_IN:         ds 1      ; contiene la tecla que se presiono, sirve para comparar
Cont_TCL:         ds 1      ;Cuantos valores se han ingresado
PATRON:           ds 1      ; contiene el patron de barrido de fila
Est_Pres_TCL:     ds 2      ;contiene el estado presente de Tarea teclado


                                Org $1010
Num_Array:        ds 6

;Aqui se colocan las estructuras de datos de la aplicacion


;===============================================================================
;                         Estructuras PantallaMUX
;===============================================================================
                                 Org $1020
EstPres_PantallaMUX:             ds 2  ;almacena estado pres
DSP1:                            ds 1  ;contenido a poner en el display 1
DSP2:                            ds 1   ;contenido a poner en el display 2
DSP3:                            ds 1   ; contenido a poner en el display 3
DSP4:                            ds 1   ;contenido a poner en el display 4
LEDS:                            ds 1   ;contiene patron de leds
Cont_Dig:                        ds 1   ;digito de display a encender
Brillo:                          ds 1   ;varia brillo de Dsp
BCD:                             ds 1   ;Resultado de num binario en bcd
Cont_BCD:                        ds 1   ; variable de 1byte
BCD1:                            ds 1   ; varibale de 1byte con resultado de BIN1
BCD2:                            ds 1    ; varibale de 1byte con resultado de BIN2
;===============================================================================
;                         Estructuras Pantalla LCD
;===============================================================================

IniDisp:                         dB $28,$28,$06,$0C,$FF
Punt_LCD:                        ds 2
CharLCD:                         ds 1
Msg_L1:                          ds 2 ;punteros para tabla ascii
Msg_L2:                          ds 2 ;punteros que contiene direccion a tabalca ascii
EstPres_SendLCD:                 ds 2
EstPres_TareaLCD:                ds 2
;===============================================================================
;                         Estructuras Tareas_PB
;===============================================================================

Est_Pres_PB1:      ds 2      ;contiene el estado presente de tarea LeerPB
Est_Pres_PB2:      ds 2      ;contiene el estado presente de tarea LeerPB

Est_Pres_TConfig:  ds 2      ;Contiene estado de tarea config
ValorVueltas:      ds 1       ;Valor de vueltas
NumVueltas:        ds 1       ;vueltas ingresadas en runtime

Est_Pres_TComp:    ds 2        ;Contiene estado de tarea competencia
Vueltas:           ds 1        ;vueltas
DeltaT:            ds 1        ;diferencial de tiempo
Veloc:             ds 1        ; velocidad promedio del ciclista
;===============================================================================
;                         Estructuras Tarea Brillo
;===============================================================================

Est_Pres_TBrillo:                 ds 2

                                Org $1070
Banderas_1:         ds 1      ;Banderas de shortp,lonp y ARRAY_OK
Banderas_2        ds 1      ;Banderas RS,LCD_Ok,FINSENDLCD,Second_LINe

;===============================================================================
;                         TABLA DE CODIGOS DE SEGMENT y TECLADO
;===============================================================================
                                 Org $1100
Segment:          dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00

                                Org $1110
Teclas:           dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$0B,$0E

;----------------------- Mensajes para la aplicación----------------------------
                                 Org $1200
;Mensajes para modo libre
MSG_LIBRE_1:     fcc "  RunMeter 623  "
                 db EOM
MSG_LIBRE_2:     fcc "   MODO LIBRE   "
                 db EOM

;Mensajes de modo configuracíon
MSG_CONF_1:      fcc " MODO CONFIGURAR"
                 db EOM
MSG_CONF_2:      fcc " NUMERO VUELTAS "
                 db EOM

;Mensajes modo competencia
MSG_INICIAL_1:    fcc "  RunMeter 623  "
                 db EOM
MSG_INICIAL_2:     fcc "  ESPERANDO...  "
                 db EOM
MSG_COMP_1:      fcc "MOD. COMPETENCIA"
                 db EOM
MSG_COMP_2:      fcc "VUELTA    VELOC "
                 db EOM
MSG_CALC:        fcc "  CALCULANDO... "
                 db EOM
MSG_ALERTA_1:    fcc "** VELOCIDAD ** "
                 db EOM
MSG_ALERTA_2:    fcc "*FUERA DE RANGO*"
                 db EOM

MSG_FIN_COMP_1:  fcc "FIN  COMPETENCIA"
                 db EOM
MSG_FIN_COMP_2:  fcc "VUELTA     VELOC"
                 db EOM



;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:
Timer260uS      ds 1
Timer40uS       ds 1
Timer1mS        ds 1       ;Timer 1 ms con base a tiempo de interrupcion
CountTicks      ds 1


Fin_BaseT       db $FF

Tabla_Timers_Base1mS

Timer10mS:      ds 1       ;Timer para generar la base de tiempo 10 mS
Timer_RebPB1:    ds 1
Timer_RebPB2:    ds 1       ;Ejemplos de timers de aplicacion con BaseT
Timer_RebTCL:   ds 1
Timer2mS:       ds 1
TimerDigito:    ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP1:      ds 1
Timer_SHP2:      ds 1
Timer100mS:     ds 1       ;Timer para generar la base de tiempo de 100 mS



Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1S:        ds 1       ;Timer para generar la base de tiempo de 1 Seg.
TimerBrillo:    ds 1
TimerVel:       ds 1
TimerPant:      ds 1
TimerFinPant:   ds 1


Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo: ds 1   ;Timer para parpadeo de led testigo
Timer_LP1:         ds 1
Timer_LP2:         ds 1
TimerError:        ds 1

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================


                               Org $2000
        Lds #$3BFF
        Cli
        ;COnfiguracion de Puerto b y P para tareas led:testigo y pantalla mux
        Movb #$FF,DDRB
        Movb #$FF,DDRP    ;Habilitar
        Movb #$10,PTP

        Bset DDRJ,$02     ;Para utilizar los 8 Leds
        Bclr PTJ,$02      ;haciendo toogle


        
        ;Config de hardware de PT
        Movb #$90,TSCR1
        Movb #$04,TSCR2 ;PRS=16
        Movb #$10,TIOS ; canal 4
        Movb #$10,TIE   ;interrupcion de canal 4
        MOvb #$01,TCTL1
        Ldd TCNT
        Addd #30
        Std TC4   ; TC4= (20uS*24Mhz)/16 = 30
        
        ;Se realzia la configuración del teclado matricial
        Movb #$F0,DDRA  ;se activa parte alta como salida y parte baja como entrada<
        Bset PUCR,$01   ;Se activan R pullup en las columnas

        ;**CONFIGURACION DE ATD**
        Movb #$C0,ATD0CTL2
        Ldaa #160

D_ATD:  Deca
        Tsta    ; Retardo de 10us para la config de ATD
        Bne D_ATD
        Movb #$10,ATD0CTL3  ;2 conversiones por ciclo
        Movb #$B3,ATD0CTL4  ; convierte a 8bits<<<< y fc=600Khz
        
        ;Configuracion Puerto H
        Bclr DDRH,$C9  ; Asegura que puertos PH7,PH6,PH3,PH0 como entradas


;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
;===============================================================================
;                 Inicialización de Estructuras de Datos
;===============================================================================
;----------------------Inicialización de Timerss--------------------------------

        Movb #tTimer1mS,Timer1mS
        Movb #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movb #tTimer100mS,Timer100mS
        Movb #tTimer1S,Timer1S
        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo
        Movb #tTimerDigito,TimerDigito
        Clr Banderas_1
;===============================================================================
;                 INICIALIZACION DE MAQUINAS DE ESTADO
;===============================================================================
        
        ;Se cargan estados iniciales de las maquinas de estado
        Movw #LeerPB_Est1_1,Est_Pres_PB1    ;Para PB
        Movw #LeerPB_Est1_2,Est_Pres_PB2    ;Para PB
        
        Movw #Teclado_Est1,Est_Pres_TCL   ; PAra TCL

        Movw #TareaLCD_Est1,EstPres_TareaLCD ;para Tarea_LCD
        Movw #SendLCD_Est1,EstPres_SendLCD   ; Send LCD
        Movw #PantallaMUX_Est1,EstPres_PantallaMUX
        Movw #TareaBrillo_Est1,Est_Pres_TBrillo
        
        Movw #TConfig_Est1,Est_Pres_TConfig    ;inicializa estado 1 en TConfig
        Movw #TComp_Est1,Est_Pres_TComp        ;inicializa estado 1 en TComp
        
        ;Se inician valores de la tabla de datos para Tarea Teclado
        Movb #$00,Cont_TCL
        Movb #$06,MAX_TCL
        Movb #$FF,Tecla
        Movb #$FF,Tecla_IN
        Movb #$00,PATRON
        

        
        ; Se inicializan las estructuras de Pantalla mux
        Movb #$01,Cont_Dig

        ;------------AQUI Se cambia el brillo--------------------------------
        Movb #$00,Brillo  ;se varia el valor de inizialización si desea cambiar
        ;--------------------------------------------------------------------
        Movb #$00,LEDS
        ;Tarea config
        MOvb #$00,ValorVueltas
        Movb #$03,NumVueltas
        ;Tarea competencia
        Movb #$00,Vueltas
        Movb #$00,Veloc
        Movb #$00,DeltaT

        ; LLENA ARREGLO NUM ARRAY CON FF  .
        Jsr Borrar_NUM_ARRAY

        ;Aqui se bandan los mensaje que se desean mandar al lcd y se activa LCD_o
;******************************************************************************
;                             Rutina para inicializar pantalla LCD
;*****************************************************************************

           Clr Banderas_2
;******************************************************************************
;                          inicializar pantalla LCD
;*****************************************************************************
Init_LCD:
           Movb #tTimer260uS,Timer260uS
           Movb #tTimer40uS,Timer40uS
           Movb #tTimer2mS,Timer2mS

           Movb #$FF,DDRK  ;se habilitan el puerto K como salidas
           Movb #$00,PORTK ; no se manda nada todavia
           Movw #IniDisp,Punt_LCD
           Ldy Punt_LCD
           Bclr Banderas_2,$FF
           Bset Banderas_2,LCD_OK ; pone bandera en uno para que no siempre se ejecute tarea led
           Ldab #$00

Init_Loop:  Movb B,Y,CharLCD ;dir indexado con acc b
            Ldaa #EOB         ; $FF
            Cmpa CharLCD      ; revisa si ya se leyeron los 5 comandos de inicialización
            Beq Clear_PAN

Recibiendo: Jsr SEND_LCD
            Brclr Banderas_2,FinSendLCD,Recibiendo  ;revisa si ya se leyó el char
            Bclr Banderas_2,FinSendLCD     ; so ya se leyo activa FInSendLCD
            INCB    ;Siguiente comando
            Bra Init_Loop

Clear_PAN:  Movb #Clear_LCD,CharLCD
R_CLEAR:    Jsr SEND_LCD
            Brclr Banderas_2,FinSendLCD,R_CLEAR ; revisa que ya se haya mandado el comando clr
            Movb #tTimer2mS,Timer2mS

mS_FIN:     Tst Timer2mS
            Bne mS_FIN
;---------------------------------FIN rutina de inicialización------------------
                   Movw #MSG_CONF_1,Msg_L1
                   Movw #MSG_CONF_2,Msg_L2  ;Carga el mensaje de config
                   Bclr Banderas_2,LCD_OK  ;se puso aqui porque si se ponia en el estado 1 no
;===============================================================================
;                       DESPACHADOR DE TAREAS
;===============================================================================
Despachador_Tareas:

                     Brset Banderas_2,LCD_OK,Otras_Tareas
                     Jsr Tarea_LCD


Otras_Tareas:        Jsr Tarea_Modo_Libre
                     Jsr Tarea_Configurar
                     Jsr Tarea_Modo_Competencia

                     Jsr Tarea_Led_Testigo
                     Jsr Tarea_Brillo
                     Jsr Tarea_PantallaMUX

                     Jsr Tarea_Teclado
                     Jsr Tarea_LEER_PB_1
                     Jsr Tarea_LEER_PB_2


                     Bra Despachador_Tareas
;===============================================================================
;                     Tarea_Modo_Libre
;Solo se activa si PH7 y PH6 estan en bajo, revisa todas las combinaciones
;posibles en los switches.
;===============================================================================
Tarea_Modo_Libre:
                     Brset PTIH,$80,Fin_Modo_libre
                     Brset PTIH,$40,Fin_Modo_libre
                     Brset PTIH,$C0,Fin_Modo_libre

                     Movb #$01,LEDS  ;Pone PB0 en alto indicando MODO libre on
                     Brclr Banderas_2,LCD_OK,Fin_Modo_Libre
                     Movw #MSG_LIBRE_1,Msg_L1
                     Movw #MSG_LIBRE_2,Msg_L2
                     Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg
                     Movb #$BB,BCD2
                     Movb #$BB,BCD1 ;pone patrones para pantalla apagada
                     Jsr BCD_7SEG  ;Deja los valores cargados para Pmux
Fin_Modo_libre:      Rts
;===============================================================================
;                     Tarea_Configurar
;Esta tarea se encarga de resivir el numero de vueltas que ingresará el operario
;pormedio del teclado matricial
;===============================================================================
Tarea_Configurar:

                   Brclr PTIH,$40,Cargar_Est1OFF ;Descarta caso  PH6:OFF
                   Brset PTIH,$C0,Cargar_Est1OFF ; Descarta caso PH7:ONy PH6:ON

                   ;Si esta activo el modo sigue el flujo normal
                   Ldx Est_Pres_TConfig
                   Jsr 0,X
                   Bra FIN_TConfig
                   ;Si se quitan los interruptores se Carga el estado 1
Cargar_Est1OFF:    Movw #TConfig_Est1,Est_Pres_TConfig

FIN_TConfig:       Rts
;---------------------------------------Estado1---------------------------------
TConfig_Est1:      Brclr Banderas_2,LCD_OK,Fin_TConfig_Est1
                   Movw #MSG_CONF_1,Msg_L1
                   Movw #MSG_CONF_2,Msg_L2  ;Carga el mensaje de config
                   Bclr Banderas_2,LCD_OK  ;se puso aqui porque si se ponia en el estado 1 no

                   MOvb #$02,LEDS
                   Ldaa NumVueltas
                   Jsr BIN_BCD_MUXP
                   Movb BCD,BCD1  ;Convierte BIN1
                   MOvb #$BB,BCD2
                   Jsr BCD_7SEG  ;Deja los valores cargados para Pmux
                   Jsr Borrar_NUM_ARRAY

                   Movw #TConfig_Est2,Est_Pres_TConfig

Fin_TConfig_Est1:  Rts
;------------------------------Estado 2-----------------------------------------
TConfig_Est2:

                   Brclr Banderas_1,ARRAY_OK,END_Fin_est2  ;activa flag ARRAY esta listo

                   Jsr BCD_BIN  ;Convierte numero de vueltas en binario
                   Ldaa ValorVueltas
                   Cmpa #MinNumVueltas  ;Para este caso 3
                   Blo  Fin_TConfig_Est2
                   Cmpa #MaxNumVueltas   ;para este caso 25
                   Bhi Fin_TConfig_Est2
                   Ldaa ValorVueltas
                   Jsr BIN_BCD_MUXP
                   Movb BCD,BCD1  ;Convierte BIN1
                   MOvb #$BB,BCD2
                   Jsr BCD_7SEG  ;Deja los valores cargados para Pmux
                   Movb ValorVueltas,NumVueltas

Fin_TConfig_Est2:  Jsr Borrar_NUM_ARRAY



END_Fin_est2:      Rts
                   

;===============================================================================
;                     Tarea_Modo_Competencia
;
;===============================================================================
Tarea_Modo_Competencia:
                         Brset PTIH,$C0,Competencia_ON
                         ;Si no esta modo comp ON carga estado 1
                         Movb #$00,Vueltas
                         Movw #TComp_Est1,Est_Pres_TComp
                         Bra FIN_Modo_TComp
Competencia_ON:
                         Ldx Est_Pres_TComp
                         Jsr 0,X

FIN_Modo_TComp:          Rts
;--------------------------Estado 1---------------------------------------------
TComp_Est1:              Ldaa Vueltas
                         Cmpa NumVueltas
                         Beq Fin_Modo_Competencia
                         Movb #$04,LEDS  ;Pone PB0 en alto indicando MODO libre on
                         Brclr Banderas_2,LCD_OK,Fin_TComp_Est1
                         Movw #MSG_INICIAL_1,Msg_L1
                         Movw #MSG_INICIAL_2,Msg_L2
                         Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg

                         Movb #$BB,BCD2
                         Movb #$BB,BCD1 ;pone patrones para pantalla apagada
                         Jsr BCD_7SEG  ;Deja los valores cargados para Pmux

                         Movw #TComp_Est2,Est_Pres_TComp
                         Bra Fin_TComp_Est1

Fin_Modo_Competencia:
                         Movw #MSG_FIN_COMP_1,Msg_L1
                         Movw #MSG_FIN_COMP_2,Msg_L2
                         Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg
                         Movw #TComp_Est3,Est_Pres_TComp
Fin_TComp_Est1:          Rts
;-----------------------------Estado 2------------------------------------------
TComp_Est2:              Brclr Banderas_1,ShortP_2,Fin_TComp_Est2

                         Movw #TComp_Est4,Est_Pres_TComp
                         Movw #MSG_INICIAL_1,Msg_L1
                         Movw #MSG_CALC,Msg_L2
                         Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg
                         Bclr Banderas_1,ShortP_2
                         Movb #tTimerVel,TimerVel
Fin_TComp_Est2:          Rts
;--------------------------------Estado3----------------------------------------
TComp_Est3:              Brclr Banderas_1,LongP_2,Fin_TComp_Est3 ;Borrado se realiza con S1 es decir PH3
                         Bclr Banderas_1,LongP_2

                         Jsr Borrar_NUM_ARRAY ; Permite borrar NUM_ARRAY si hay LONGP
                         Movb #$00,Vueltas
                             Movw #TComp_Est1,Est_Pres_TComp
FIN_TComp_Est3:          Rts
;----------------------------Estado 4-------------------------------------------
TComp_Est4:              Brclr Banderas_1,ShortP_1,Fin_TComp_Est4
                         ;Cicilista llego a S2, se llama a calcula
                         Jsr Calcula
                         Bclr Banderas_1,ShortP_1
                         Ldaa Veloc
                         Cmpa #VelocMin
                         Blo Cambio_TConfig_Alarma
                         Cmpa #VelocMax
                         Bhi Cambio_TConfig_Alarma
Veloc_valida:            Inc Vueltas
                         Movw #TComp_Est5,Est_Pres_TComp
                         Bra FIN_TComp_ESt4

Cambio_TConfig_Alarma:   Movw #MSG_ALERTA_1,Msg_L1
                         Movw #MSG_ALERTA_2,Msg_L2
                         Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg

                         Movb #$AA,BCD2
                         Movb #$AA,BCD1 ;pone patrones para pantalla apagada
                         Jsr BCD_7SEG  ;Deja los valores cargados para Pmux

                         Movb #tTimerError,TimerError
                         Movw #TComp_Est6,Est_Pres_TComp
FIN_TComp_Est4:          Rts
;--------------------------Estado 5---------------------------------------------
TComp_Est5:              Tst TimerPant
                         Bne FIN_TComp_Est5

                         Movw #MSG_COMP_1,Msg_L1
                         Movw #MSG_COMP_2,Msg_L2
                         Bclr Banderas_2,LCD_OK ;se quita la bandera para enviar msg

                         Ldaa Vueltas

                         Jsr BIN_BCD_MUXP
                         Movb BCD,BCD2  ;Convierte BIN1

                         Ldaa Veloc
                         Jsr BIN_BCD_MUXP
                         
                         MOvb BCD,BCD1
                         Jsr BCD_7SEG  ;Deja los valores cargados para Pmux
                         Movw #TComp_Est7,Est_Pres_TComp
FIN_TComp_Est5:          Rts
;--------------------------Estado 6---------------------------------------------
TComp_Est6:              Tst TimerError
                         Bne FIN_TComp_Est6
                         Movw #TComp_Est1,Est_Pres_TComp

FIN_TComp_Est6:          Rts
;---------------------------Estado 7--------------------------------------------
TComp_Est7:              Tst TimerFinPant
                         Bne FIN_TComp_Est7
                         Movw #TComp_Est1,Est_Pres_TComp
FIN_TComp_Est7:          Rts
;===============================================================================
;                     Tarea_Brillo
; Tarea se encarga de controlar el brillo de los displays de 7 segmentos, donde
;el brillo depende de la posicón del timer VR2 ya que se esta convirtiendo la
;Tensión mediante el convertidor AD
;===============================================================================
Tarea_Brillo:   Ldx Est_Pres_TBrillo
                Jsr 0,X
FIN_TBrillo:    Rts
;----------------------------Estado 1-------------------------------------------
TareaBrillo_Est1:   Movb #tTimerBrillo,TimerBrillo
                    Movw #TareaBrillo_Est2,Est_Pres_TBrillo
                    Rts
;-----------------------------Estado 2------------------------------------------
TareaBrillo_Est2:   Tst TimerBrillo
                    Bne Fin_Tbrillo_Est2
                    Movb #$87,ATD0CTL5  ; escoge  Pad7 que es el del POT, inicia
                                        ;ciclo de conversion
                    Movw #TareaBrillo_Est3,Est_Pres_TBrillo
                    
Fin_TBrillo_Est2:   Rts
;---------------------------------Estado 3--------------------------------------
TareaBrillo_Est3: Brclr ATD0STAT0,$80,Fin_TBrillo_Est3 ;revisa si ya finalizó ciclo de conversion
                  Ldd  ADR00H
                  Addd ADR01H
                  Lsrd        ;mimso a dividir entre 2
                  Ldy #100
                  Emul
                  Ldx #255   ;B^N-1
                  Idiv        ; valor de brillo = (codigo*100)/255
                  Tfr X,D
                  Stab Brillo
                  Movw #TareaBrillo_Est1,Est_Pres_TBrillo
Fin_TBrillo_Est3: Rts

;===============================================================================
;                     Tarea_teclado
;Se implementa con una máquina de 4 estados y utiliza una subrutina denominada
;Leer_Teclada y la interrupción RTI para suspención de rebotes
;===============================================================================
Tarea_Teclado:       Ldx Est_Pres_TCL
                     Jsr 0,X
FinTareaTeclado:     Rts
;-----------------------Primer estado-------------------------------------------
Teclado_Est1:           Jsr Leer_teclado
                        Ldaa Tecla_IN
                        Cmpa #$FF ;revisa si hay valor en tecla
                        Beq FIN_Teclado_Est1 ; si no se lee valor queda en est1
                        Movb Tecla_IN,Tecla ; guarda valor para comparar en est2
                        Movb #tSubRebTCL,Timer_RebTCL
                        Movw #Teclado_Est2,Est_Pres_TCL

FIN_Teclado_Est1:       Rts
;--------------------Segundo estado---------------------------------------------
Teclado_Est2:           Tst Timer_RebTCL
                        Bne FIN_Teclado_Est2
                        Jsr Leer_Teclado
                        Ldaa Tecla_IN
                        Cmpa Tecla  ;Revisa si se presionó la misma tecla
                        Beq Pres_V
                        Movw #Teclado_Est1,Est_Pres_TCL ; ruido vuelve al est1
                        Bra FIN_Teclado_Est2

Pres_V:                 Movb Tecla_IN,Tecla   ;Se guarda valor real
                        Movw #Teclado_Est3,Est_Pres_TCL ;Si hay valor pasa a est3

FIN_Teclado_Est2:       Rts
;---------------------Tercer estado---------------------------------------------
Teclado_Est3:           Jsr Leer_Teclado
                        Ldaa Tecla_IN
                        Cmpa #$FF  ;revisa si tecla sigue presionada
                        Bne FIN_Teclado_Est3
                        Movw #Teclado_Est4,Est_Pres_TCL ;Ya se solto la tecla
FIN_Teclado_Est3:       Rts
;-------------------------Cuarto Estado-----------------------------------------
Teclado_Est4:           Ldaa Cont_TCL
                        Ldy #Num_Array
                        Cmpa MAX_TCL

                        Beq ENTER_BORRAR

                        ;Comienzan acciones para formar array
                        Tst Cont_TCL
                        Bne TECLAS_NORMALES

                        ;AQUI VA el caso primera tecla
                        Ldaa Tecla
                        Cmpa #$0B
                        Beq FIN_Teclado_Est4  ; revisa caso borrar
                        Cmpa #$0E
                        Beq FIN_Teclado_Est4   ;Caso enter
                        Ldaa Cont_TCL
                        Movb Tecla,A,Y  ;Guarda valor de la primera tecla
                        Inc Cont_TCL
                        Bra FIN_Teclado_Est4

TECLAS_NORMALES:        Ldaa Tecla
                        Cmpa #$0B
                        Beq Est4_BORRAR ;borra
                        Cmpa #$0E
                        Beq ENTER_Est4 ;enter
                        Ldaa Cont_TCL
                        Movb Tecla,A,Y ;guarda valor en num ARRAY
                        Inc Cont_TCL
                        Bra FIN_Teclado_Est4

ENTER_BORRAR:           Ldaa Tecla
                        Cmpa #$0B
                        Beq Est4_BORRAR
                        Cmpa #$0E
                        Beq ENTER_Est4
                        ;Si no es enter o borrar debería de saltar a est1.
                        Bra FIN_Teclado_Est4

Est4_BORRAR:            Dec Cont_TCL   ;Se resta 1 para poder borrar dir anterior
                        Ldaa #$FF
                        Ldab Cont_TCL
                        Staa b,Y      ; Guarda el vacio en num array
                        Bra FIN_Teclado_Est4

ENTER_Est4:             Movb #$00,Cont_TCL   ;cuando hay enter se vuelve de 0
                        Bset Banderas_1,ARRAY_OK  ;activa flag ARRAY esta listo


FIN_Teclado_Est4:       Movb #$FF,Tecla     ;se borran los valores de tecla y tecla_IN
                        Movb #$FF,Tecla_IN
                        Movw #Teclado_Est1,Est_Pres_TCL ;regresa al estado 1
                        Rts
;===============================================================================
;                     SUBRTINA Leer_teclado
;Se encarga de leer el teclado de manera multiplexada leyendo fila por fila
;Viendo si se presiona alguna de las teclas y guardando el valor en tecla_IN
;===============================================================================
Leer_teclado:          Ldy #Teclas   ; se utilizara indice x para barrer tabla
                       Movb #$EF,PATRON  ; inicializa PATRON En EF
                       Ldaa #$00      ; Donde se cargará el offset para teclas

                       ;Se revisa si se presiona alguna de las columnas
Loop_teclado:          Movb PATRON,PORTA  ;pasa valor para leer num de fila
                       nop
                       nop
                       nop
                       Brclr PORTA,Mask_COL1,Columna1 ;Revisa si se presiona tecla de col 1
                       Brclr PORTA,Mask_COL2,Columna2  ;revisa tecla de col 2
                       Brclr PORTA,Mask_COL3,Columna3  ;revisa tecla de col 3
                       ;Si no se presiona ninguna tecla se pasa a la siguiente fila
                       LSL PATRON
                       Adda #$03 ; se le suma 3 para la siguiente fila
                       Ldab #$F0
                       Cmpb PATRON      ;se revisa si ya se leyó todo el teclado
                       Bne Loop_teclado
                       Movb #$FF,Tecla_IN  ; No leyó nada guarda $FF en tecla
                       Bra Retornar_Leer_teclado

Columna3:              Inca  ;Revisa por los valores de la tercera col 3,6,9,B en teclas
                             ;3*n+2

Columna2:              Inca   ;Revisa por los numeros de la columna del centro
                              ;3*n+1, valores 2,5,8,00 en teclas

Columna1:              Movb a,Y,Tecla_IN ;Guarda el valor en BCD en tecla a partir
                                      ; de tabla Teclas por dir inexado por acc

Retornar_Leer_teclado: Rts

;*******************************************************************************
;                               TAREA LED TESTIGO
;*******************************************************************************

Tarea_Led_Testigo:

                Tst Timer_LED_Testigo  ;revisa si ya paso 1 seg para cambiar de color
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo

                Brset PTP,$10,Led_Verde ;revisa si rojo esta encendido
                Brset PTP,$20,Led_Azul ;revisa si verde esta encendido
                Brset PTP,$40,Led_Rojo ;revisa si azul esta encendido

Led_Verde:      Bclr PTP,$10
                Bset PTP,$20    ;cambia a led verde
                Bra FinLedTest

Led_Azul:       Bclr PTP,$20
                Bset PTP,$40   ;cambia a led azul
                Bra FinLedTest

Led_Rojo:       Bclr PTP,$40
                Bset PTP,$10  ;cambia aled rojo
                Bra FinLedTest
                
FinLedTest:     Rts
;===============================================================================
;                        Tarea LEER_PB
;esta tarea lee si se presiona el boton de PH0
;===============================================================================
Tarea_LEER_PB_1:  Ldx Est_Pres_PB1
                  Jsr 0,X
FinTareaPB_1:     Rts
;-------------------Primer estado----------------------------------------------
LeerPB_Est1_1:          BRSET PortPB,MaskPB,LeerPB_FIN1_1
                        MOVB #tSubRebPB,Timer_RebPB1
                        MOVB #tShortP,Timer_SHP1
                        MOVB #tLongP,Timer_LP1

                        MOVW #LeerPB_Est2,Est_Pres_PB1

LeerPB_FIN1_1:          RTS
;-----------------Segundo estado-----------------------------------------------
LeerPB_Est2:    Tst Timer_RebPB1
                Bne Return2
                BrClr PortPB,MaskPB,Cambio_est
                Movw #LeerPB_Est1_1,Est_Pres_PB1
                Bra Return2
Cambio_est:     Movw #LeerPB_Est3,Est_Pres_PB1

Return2:        Rts
;---------------------Tercer estado---------------------------------------------
LeerPB_Est3:    Tst Timer_SHP1
                Bne Return3
                BrClr PortPB,MaskPB,Cambio_est4
                Bset Banderas_1,ShortP_1
                Movw #LeerPB_Est1_1,Est_Pres_PB1
                Bra Return3
Cambio_est4:    Movw #LeerPB_Est4,Est_Pres_PB1

Return3:        Rts

;-------------------------Cuarto Estado-----------------------------------------
LeerPB_Est4:   Tst Timer_LP1
               Bne SHORTPRESS
               Brclr PortPB,MaskPB,Return4
               Bset Banderas_1,LongP_1
               MOVW #LeerPB_Est1_1,Est_Pres_PB1
               Bra Return4

SHORTPRESS:    Brclr PortPB,MaskPB,Return4
               Bset Banderas_1,ShortP_1

               Movw #LeerPB_Est1_1,Est_Pres_PB1
Return4:       Rts
;===============================================================================
;                        Tarea LEER_PB_2
;Se encarga de leer si se presiona el boton en PH3
;===============================================================================
Tarea_LEER_PB_2:  Ldx Est_Pres_PB2
                  Jsr 0,X
FinTareaPB_2:     Rts
;-------------------Primer estado----------------------------------------------
LeerPB_Est1_2:          BRSET PortPB,MaskPB_2,LeerPB_FIN1_2
                        MOVB #tSubRebPB,Timer_RebPB2
                        MOVB #tShortP,Timer_SHP2
                        MOVB #tLongP,Timer_LP2

                        MOVW #LeerPB_Est2_2,Est_Pres_PB2

LeerPB_FIN1_2:          RTS
;-----------------Segundo estado-----------------------------------------------
LeerPB_Est2_2:    Tst Timer_RebPB2
                  Bne Return2_2
                  BrClr PortPB,MaskPB_2,Cambio_est_2
                  Movw #LeerPB_Est1_2,Est_Pres_PB2
                  Bra Return2_2
Cambio_est_2:     Movw #LeerPB_Est3_2,Est_Pres_PB2

Return2_2:        Rts
;---------------------Tercer estado---------------------------------------------
LeerPB_Est3_2:    Tst Timer_SHP2
                  Bne Return3_2
                  BrClr PortPB,MaskPB_2,Cambio_est4_2
                  Bset Banderas_1,ShortP_2
                  Movw #LeerPB_Est1_2,Est_Pres_PB2
                  Bra Return3_2
Cambio_est4_2:    Movw #LeerPB_Est4_2,Est_Pres_PB2

Return3_2:        Rts

;-------------------------Cuarto Estado-----------------------------------------
LeerPB_Est4_2:   Tst Timer_LP2
                 Bne SHORTPRESS_2
                 Brclr PortPB,MaskPB_2,Return4_2
                 Bset Banderas_1,LongP_2
                 MOVW #LeerPB_Est1_2,Est_Pres_PB2
                 Bra Return4

SHORTPRESS_2:    Brclr PortPB,MaskPB_2,Return4
                 Bset Banderas_1,ShortP_2

                 Movw #LeerPB_Est1_2,Est_Pres_PB2
Return4_2:       Rts
;===============================================================================
;                     Tarea_PantallaMUX
;Maquina de estados que se encarga de multiplexar em los displays de 7 segmentos
; y en el puerto de los leds de la dragon 12
;===============================================================================
Tarea_PantallaMUX:   Ldx EstPres_PantallaMUX
                     Jsr 0,X
FinPantallaMUX:      Rts
;-----------------------Primer estado-------------------------------------------
PantallaMUX_Est1:          Tst TimerDigito

                           LBne FIN_PantallaMUX_Est1

                           Movb #tTimerDigito,TimerDigito   ;se revisa cual disp
                           Ldab Cont_Dig                    ; se va a encender
                           cmpb #$01
                           Beq Digito_1
                           cmpb #$02
                           Beq Digito_2
                           Cmpb #$03
                           Beq Digito_3
                           Cmpb #$04
                           Beq Digito_4
                           ;Caso para habilitar Leds


                           Bclr PTJ,$02
                           Movb LEDS,PORTB
                           Movb #$01,Cont_Dig
                           Bra  Cambio_PantallaMux
Digito_1:
                           Bset PTP,$0E
                           Bclr PTP,$01  ; se enciende el display mas significativo
                           Movb DSP1,PORTB ; carga valor
                           Inc Cont_Dig
                           Bra Cambio_PantallaMUX

Digito_2:
                           Bset PTP,$0D
                           Bclr PTP,$02     ;ecnience display 2
                           Movb DSP2,PORTB
                           Inc Cont_Dig
                            Bra Cambio_PantallaMUX
Digito_3:
                           Bset PTP,$0B
                           Bclr PTP,$04       ;enciende display 3
                           Movb DSP3,PORTB
                           Inc Cont_Dig
                            Bra Cambio_PantallaMUX
Digito_4:
                           Bset PTP,$07
                           Bclr PTP,$08    ;enciende Display 4
                           Movb DSP4,PORTB
                           Inc Cont_Dig



Cambio_PantallaMux:        Movb #tMaxCountTicks,CountTicks   ;se cargan 100 ticks
                           Movw #PantallaMUX_Est2,EstPres_PantallaMUX

FIN_PantallaMUX_Est1:      Rts
;--------------------Segundo estado---------------------------------------------
PantallaMUX_Est2:          Ldaa #tMaxCountTicks
                           suba CountTicks    ; control brillo = 100-count_ticks
                           Cmpa Brillo  ; revisa valor del brillo
                           Blo FIN_PantallaMux_Est2
                           Bset PTP,$0F   ;apaga todos los displays

                           Bset PTJ,$02
                           Movw #PantallaMUX_Est1,EstPres_PantallaMUX
FIN_PantallaMUX_Est2:      Rts

;===============================================================================
;                     Tarea Send_LCD
;tarea define el protocolo estroboscópico para enviar al LCD un byte de contenido
; es decir permite la comunicación con la pantalla LCD para que esta pueda
; desplegar valores o letras
;===============================================================================
SEND_LCD:            Ldx EstPres_SendLCD
                     Jsr 0,X
FIN_SENDLCD:         Rts
;-----------------------Primer estado-------------------------------------------
SendLCD_Est1:        Ldaa CharLCD
                     Anda #$F0
                     Lsra
                     Lsra ; para poder mandar de portk5-portk2
                     Staa PORTK
                     Brset Banderas_2,RS,DATO_LCD
                     ;si no es 0 se pone en 1
                     Bclr PORTK,RS
                     Bra Hab_LED_EST1
DATO_LCD:            Bset PORTK,RS

Hab_LED_EST1:        Bset PORTK,$02    ; enable lcd
                     Movb #tTimer260uS,Timer260uS
                     Movw #SendLCD_Est2,EstPres_SendLCD
FIN_SendLCD_Est1:    Rts
;-----------------------Segudno Estado------------------------------------------
SendLCD_Est2:         Tst Timer260uS
                      Bne FIN_SendLCD_Est2
                      Bclr PORTK,$02   ;Desabilita LCD

                      Ldaa CharLCD
                      Anda #$0F
                      Lsla
                      Lsla
                      Staa PORTK
                      Brset Banderas_2,RS,DATO_LCD_Est2
                     ;si esun comando la pone en 0 Rs
                      Bclr PORTK,RS
                      Bra Hab_LED_EST2
DATO_LCD_Est2:        Bset PORTK,RS

Hab_LED_EST2:         Bset PORTK,$02    ; enable lcd
                      Movb #tTimer260uS,Timer260uS
                      Movw #SendLCD_Est3,EstPres_SendLCD

FIN_SendLCD_Est2:     Rts
;-----------------------Tercer Estado-------------------------------------------
SendLCD_Est3:         Tst Timer260uS
                      Bne FIN_SendLCD_Est3
                      Bclr PORTK,$02   ;Desabilita LCD
                      Movb #tTimer40uS,Timer40uS
                      Movw #SendLCD_Est4,EstPres_SendLCD
FIN_SendLCD_Est3:     Rts
;----------------------------Cuarto estado--------------------------------------
SendLCD_Est4:         Tst Timer40uS    ; estado espera a que pasen 40us
                      Bne Fin_SendLCD_Est4
                      Bset Banderas_2,FinSendLCD ;activa FinsendLCD
                      Movw #SendLCD_Est1,EstPres_SendLCD
Fin_SendLCD_Est4:     Rts

;===============================================================================
;                     Tarea_LCD
;Tarea para mandar mensaje mediante enviar Char LCD
;===============================================================================
Tarea_LCD:            Ldx EstPres_TareaLCD
                      Jsr 0,X
FIN_TareaLCD:         Rts
;---------------------------Primer Estado---------------------------------------
TareaLCD_Est1:        Bclr Banderas_2,RS  ;se va a mandar comando de linea
                      Bclr Banderas_2,FinSendLCD

                      Brset Banderas_2,Second_Line,ACTIVE_L2

                      Movb #ADD_L1,CharLCD
                      Movw Msg_L1,Punt_LCD   ;carga mensaje 1

                                            ; a est2
                      Bra SEND_MSG:

ACTIVE_L2:            Movb #ADD_L2,CharLCD
                      Movw Msg_L2,Punt_LCD   ;Carga mensaje 2
                                        ;


SEND_MSG:             Jsr SEND_LCD
                      Movw #TareaLCD_Est2,EstPres_TareaLCD
FIN_TareaLCD_Est1:    Rts

;------------------------------Segundo Estado-----------------------------------
TareaLCD_Est2:       Brclr Banderas_2,FinSendLCD,Ver_CharLCD
                     Bclr Banderas_2,FinSendLCD
                     Bset Banderas_2,RS       ;se envia el caracter

                     Ldy Punt_LCD       ;carga puntero
                     Ldaa 0,Y
                     INY                ; aumenta y se vuelve a guardar
                     Sty Punt_LCD

                     Staa CharLCD              ;guarda el valor del msg en CharLCD
                     Cmpa #EOB
                     Bne Ver_CharLCD

                     Brclr Banderas_2,Second_Line,Poner_SL  ;Revisa si se envio MSG2
                     Bclr Banderas_2,Second_Line
                     Bset Banderas_2,LCD_OK
                     Bra Reg_Est1_LCD

Poner_SL:            Bset Banderas_2,Second_Line    ;activa secondLIne

Reg_Est1_LCD:
                     Movw #TareaLCD_Est1,EstPres_TareaLCD   ;Pasa a est1
                     Bra FIN_TareaLCD_Est2



Ver_CharLCD:         Jsr SEND_LCD  ;caso en el que no se envía charLCD


FIN_TareaLCD_Est2:   Rts




                     
;===============================================================================
;                     Subrutina_BCD_BIN
;Tarea recive valor a convertir por medio de la direccion de memoria NUM_ARRAY,
; y guardara el resultado en ValorVueltas
;===============================================================================
BCD_BIN:             Ldy #Num_Array
                     Ldaa 0,Y
                     Ldab #10
                     Mul
                     Addb 1,Y
                     Stab ValorVueltas
                     Rts
;===============================================================================
;                     Subrutina_Calcula
;Subrutina calcula los valores de DeltaT, Velocidad promedio y tiempos de los
;Timers para determinar en que lugar se encuentra el ciclista.
;Recibe sus valores por medio de memoria
;
;===============================================================================
Calcula:             ;primero se calcula delta T en base 100mS
                     Ldab #tTimerVel
                     Subb TimerVel
                     Stab DeltaT ; DeltaT= 100-TimerVel porque es decremental

                     Ldaa #$00    ;D=00:DeltaT
                     Ldab DeltaT

                     ;Ahora se calcula velocidad
                     Tfr D,X    ;X= DeltaT

                     Ldd #FactorConv
                     Idiv         ;D/X
                     Tfr X,D
                     Stab Veloc   ;Veloc= FactorConv/DeltaT

                     ;Ahora se calcula el TimerPant
                        ;calcula tiempo que tarda de S2 a meta

                     Ldaa #$00
                     Ldab Veloc
                     Tfr D,X     ; X=Veloc
                     Ldd #FactorConv2

                     Idiv
                     Tfr X,D
                     Stab TimerPant    ;TimerPant= FactorConv2/Velocidad
                     
                     ;Ahora se calcula el TimerPantFin
                     ;Tiempo que tarda de S2 a la pantalla
                     Ldab Veloc
                     Ldaa #$00
                     Tfr D,X     ; X=Veloc
                     Ldd #FactorConv3

                     Idiv
                     Tfr X,D
                     Stab TimerFinPant    ;TimerFinPant= FactorConv3/Velocidad
                     Rts
                     
;===============================================================================
;                     SUBRTINA BIN_BCD_MUXP
;Convierte valores de Binario a Bcd  utilizando el algoritmo visto en clase
;===============================================================================
BIN_BCD_MUXP:        Movb #$00,BCD
                     Ldy #$07
                     Ldab #$00
For_BIN_BCD:         Lsla          ;desplaza el numero BIN
                     Rol BCD       ; se va formando el numero en BCD
                     Staa Cont_BCD
                     
                     Ldaa #$0F
                     Anda BCD
                     Cmpa #$05
                     Blo Sig_BCD
                     Adda #$03


Sig_BCD:             Tab       ;Se pasa al B para luego sumarlo con la parte alta
                     Ldaa #$F0
                     Anda BCD
                     Cmpa #$50
                     Blo  Sig_BCD2
                     Adda #$30


Sig_BCD2:            Aba       ; Parte alta en A mas parte baja en B BCD
                     Staa BCD
                     Ldaa Cont_BCD
                     Dbne Y,For_BIN_BCD
                     Lsla
                     Rol BCD
                     Rts
                     
;===============================================================================
;                     SUBRTINA BCD_7SEG
;Mediante dir indirecto por acomulador esta subrutina carga los valores para que
;puedan ser desplegados en el dsiplay de la pantalla multiplexada.
;===============================================================================
BCD_7SEG:           Ldy #Segment

                    ;Primero se pasan los valores de BCD2
                    Ldaa BCD2
                    Lsra            ; la parte alta se desplaza 4 veces para dejarla
                    Lsra             ; $0X
                    Lsra
                    Lsra
                    Movb a,Y,DSP1   ; utiliza dir indexado con acc A

                    Ldaa BCD2
                    Anda #$0F
                    Movb a,Y,DSP2 ; utiliza dir indexado con acc A
                    ;Ahora con los numeros de BCD1
                    Ldaa BCD1
                    Lsra
                    Lsra
                    Lsra
                    Lsra
                    Movb a,Y,DSP3 ; utiliza dir indexado con acc A

                    Ldaa BCD1
                    Anda #$0F
                    Movb a,Y,DSP4   ; utiliza dir indexado con acc A
                    Rts

;===============================================================================
;_______________________________________________________________________________
;                               Subrutina Borra_Num_Array
;Borra num array llenandolo de FF
;...............................................................................
Borrar_NUM_ARRAY: Ldx #Num_Array
                  Ldaa #$00       ; Se borra array de 0 a max_TCL
Borrando:         Cmpa MAX_TCL
                  Beq Array_Borrado
                  Movb #$FF,A,X    ;direccioniento indexado por acc
                  Inca              ;inc posicion de offset
                  Bra  Borrando    ; borra hasta que a = max_TCL
Array_Borrado:    Bclr Banderas_1,ARRAY_OK
                  Rts
                  

;******************************************************************************
;                       SUBRUTINA DE ATENCION A Ouput Compare
;******************************************************************************

Maquina_Tiempos:        LDX #Tabla_Timers_BaseT
                        JSR Decre_Timers
                        LDAA Timer1mS
                        BNE FIN
                        MOVB #tTimer1mS,Timer1mS
                        LDX #Tabla_Timers_Base1mS

                        JSR Decre_Timers
                        LDAA Timer10mS
                        BNE FIN
                        MOVB #tTimer10ms,Timer10mS
                        LDX #Tabla_Timers_Base10mS

                        JSR Decre_Timers
                        LDAA Timer100mS
                        BNE FIN
                        MOVB #tTimer100ms,Timer100mS
                        LDX #Tabla_Timers_Base100mS

                        JSR Decre_Timers
                        LDAA Timer1S
                        BNE FIN
                        MOVB #tTimer1S,Timer1S
                        LDX #Tabla_Timers_Base1S

                        JSR Decre_Timers

FIN:                    Ldd TCNT
                        Addd #30
                        Std TC4
                        RTI
;===============================================================================
;                     SUBRUTINA DECREMETE TIMERS
; Esta subrutina decrementar los timers colocados en un arreglo apuntado por X,
; que es el unico parametro que recibe. Los timers son de 1 byte y son decremen-
; tados si su contenido es cero. Se utiliza el marcador $FF como fin del arreglo
;===============================================================================
Decre_Timers:           tst 0,x
                        BEQ AUMENTE
                        LDAA 0,X
                        CMPA #$FF
                        BEQ FinDecreTimers
                        DEC 0,X

AUMENTE:                INX
                        BRA Decre_Timers

FinDecreTimers  Rts
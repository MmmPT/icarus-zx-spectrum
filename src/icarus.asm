; ============================================
;  APANHA! V8  -  jogo para ZX Spectrum 48K
;  O/P ou Kempston | ESPACO = pausa
;  - objetos com velocidades proprias
;    (bombas rapidas, coracoes lentos)
;  - vento que desvia os objetos
;  - NUVEM boss a cada 25 pontos
;  - brilho de apanho junto a raquete
;  Compilar: pasmo --tapbas apanha.asm apanha.tap
; ============================================

        org 32768

CHAN_OPEN equ $1601
CLS       equ $0D6B
BEEPER    equ $03B5

UDG_SV    equ $5C7B
ATTR_P    equ $5C8D
BORDCR    equ $5C48

PAD_L     equ 144
PAD_M     equ 145
PAD_R     equ 146
STAR1     equ 147
HEART     equ 148
STAR2     equ 149
BOMB      equ 150
GOLD_C    equ 151
BOLT_C    equ 154
BLOCK_C   equ 161          ; bloco solido para o logotipo grande
HOUR_C    equ 165          ; ampulheta (Cronos)
ZT_L      equ 155
ZT_M      equ 156
ZT_R      equ 157
ZB_L      equ 158
ZB_M      equ 159
ZB_R      equ 160

T_STAR    equ 1
T_BOMB    equ 2
T_HEART   equ 3
T_GOLD    equ 4
T_BOLT    equ 5
T_WIDE    equ 6
T_SHIELD  equ 7
T_UFOF    equ 8             ; ovni ja a cair (apanhavel como um item normal)
T_SNAKE   equ 9             ; serpente da Medusa (obstaculo)

AT_STAR   equ $46
AT_BOMB   equ $42
AT_HEART  equ $43

NITEMS    equ 3
ISIZE     equ 4             ; (tipo,coluna,linha,velocidade)
SPEED_INI equ 2
SPEED_MAX equ 8
GOLD_PTS  equ 20
UFO_PTS   equ 30
Y_SPAWN   equ 24            ; 2 linhas abaixo do painel (nuvem na linha 2)
Y_CATCH   equ 170           ; resolve fundido NO corpo da raquete
Y_MIN     equ 8
Y_MAX     equ 176           ; pode desenhar ate ao fundo (com OR)
Y_OVER    equ 168           ; zona da raquete desenha em OR
BOOM_Y    equ 160
SPARK_Y   equ 164

; ============================================
start:
        ld hl,udg_data
        ld (UDG_SV),hl
        ld a,$07
        ld (ATTR_P),a
        ld (BORDCR),a
        xor a
        out ($FE),a
; --- deteccao ROBUSTA de Kempston ---
; Um Kempston genuino em repouso devolve $00 (todos os bits a 0) de forma
; estavel. Nos 128K "toastrack" e +2 (grey) SEM Kempston, a porta $1F
; flutua e pode devolver valores como $1F/$FF, que a deteccao antiga
; confundia com um joystick, injetando lixo que bloqueava o teclado O/P.
; Agora so ativamos o Kempston se varias leituras derem exatamente $00.
        in a,($1F)
        or a
        jr nz,no_kemp       ; qualquer bit a 1 -> nao e Kempston em repouso
        in a,($1F)
        or a
        jr nz,no_kemp       ; segunda leitura para confirmar estabilidade
        in a,($1F)
        or a
        jr nz,no_kemp       ; terceira leitura: bus flutuante variaria
        ld a,1
        ld (kemp),a
no_kemp:
        call detect_ay
        ld a,2
        call CHAN_OPEN
        jp title

; desenha "ICARUS" em letras grandes de blocos (4x5 celulas cada)
draw_logo:
        ld b,0
dl_L:   ld a,b
        cp 6
        ret z
        push bc
        ld c,0
dl_R:   ld a,c
        cp 5
        jr z,dl_rdone
        push bc
        ld a,b
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        ld e,a
        ld d,0
        add hl,de
        ld a,c
        add a,l
        ld l,a
        jr nc,dl_noc
        inc h
dl_noc: ld de,logo_pat
        add hl,de
        ld a,(hl)
        ld e,a
        ld a,22
        rst 16
        ld a,c
        rst 16
        ld a,b
        add a,a
        add a,a
        add a,b
        add a,1
        rst 16
        ld a,16
        rst 16
        ld a,6
        rst 16
        ld a,19
        rst 16
        ld a,1
        rst 16
        ld d,4
dl_bit: ld a,e
        and 8
        jr z,dl_sp
        ld a,BLOCK_C
        jr dl_pr
dl_sp:  ld a,' '
dl_pr:  rst 16
        sla e
        dec d
        jr nz,dl_bit
        pop bc
        inc c
        jr dl_R
dl_rdone:
        pop bc
        inc b
        jr dl_L

; ============================================
title:
        call CLS
        ld a,2
        call CHAN_OPEN      ; forcar canal S: CLS pode deixar K/P activo
        call draw_logo
        ld hl,t_credits
        call print_str
        ld hl,t_legend1
        call print_str
        ld hl,t_legend2
        call print_str
        ld hl,t_info1
        call print_str
        ld hl,t_info2
        call print_str
        ld hl,t_info3
        call print_str
        ld hl,t_info4
        call print_str
        ld hl,t_boss
        call print_str
        ld hl,t_keys
        call print_str
        ld hl,t_pause
        call print_str
        ld hl,t_rec
        call print_str
        ld a,(hstab+0)
        rst 16
        ld a,(hstab+1)
        rst 16
        ld a,(hstab+2)
        rst 16
        ld a,' '
        rst 16
        ld hl,(hstab+3)
        call print_num5
        ld hl,t_press
        call print_str
        ld a,(music_enabled)
        or a
        ld hl,msg_music_on
        jr nz,tt_mshow
        ld hl,msg_music_off
tt_mshow:
        call print_str
        ld a,(music_enabled)
        or a
        call nz,play_melody
        call wait_key_anim
        jp game_init

; ============================================
game_init:
        call CLS
        ld a,2
        call CHAN_OPEN      ; forcar canal S: CLS pode deixar K/P activo
        ld hl,0
        ld (score),hl
        ld (tick),a
        ld (score10),a
        ld hl,200
        ld (next_boss),hl
        ld (gover),a
        ld (bolt_cnt),a
        ld (boss_type),a
        ld (boss_pending),a
        ld (boss_rotation),a
        ld (boss_frm),a
        ld (wind),a
        ld a,100
        ld (wind_cnt),a
        ld a,5
        ld (lives),a
        ld a,14
        ld (padx),a
        ld (last_x),a
        ld a,112
        ld (padpx),a
        ld a,3
        ld (pwid),a
        ld a,232
        ld (pmax),a
        xor a
        ld (wide_t),a
        ld (combo),a
        ld (best_combo),a
        ld (shield_active),a
        ld hl,0
        ld (shield_timer),hl
        ld (ctrl_swap),a
        ld (swap_timer),hl
        ld (ufo_active),a
        ld (rock_active),a
        ld (hit_active),a
        ld (hs_beaten),a
        ld (zeus_count),a
        ld a,SPEED_INI
        ld (speed),a
        ld a,1
        ld (spawn_cnt),a
        ld hl,items
        ld b,NITEMS*ISIZE
        xor a
clr_i:  ld (hl),a
        inc hl
        djnz clr_i
        call init_stars
        ld a,(border_tab)
        ld (cur_border),a
        out ($FE),a
        call draw_hud
        call draw_paddle

; ================= ciclo principal =================
main:
        halt
        call music_step     ; musica AY (so 128K)
        call check_pause
        call twinkle_far    ; estrelas de fundo: paralaxe lenta
        call twinkle_near   ; estrelas de fundo: paralaxe rapida
        call comet_step     ; estrela cadente ocasional
        call ufo_step       ; ovni bonus ocasional
        call rock_step      ; blocos de rocha (mesmo com Zeus ativo)
        call banner_step    ; apagar mensagens temporarias
        call hit_fx_step    ; animacao de acerto/falha, sem bloquear o jogo
        ld a,(tick)
        inc a
        ld (tick),a
        and 8
        jr z,anim_a
        ld hl,spr_star2
        ld a,$47
        jr anim_b
anim_a: ld hl,spr_star1
        ld a,$46
anim_b: ld (anim_ptr),hl
        ld (gold_at),a

; ---- raquete: le teclado/joystick a CADA frame ----
        ld a,$DF
        in a,($FE)
        cpl
        and %00000011
        ld b,a
        ld a,(kemp)
        or a
        jr z,pnj_
        in a,($1F)
        and %00000011
        or b
        ld b,a
pnj_:
; --- comandos trocados (efeito da serpente da Medusa) ---
        ld a,(ctrl_swap)
        or a
        jr z,pnj_go
; trocar bit 0 (direita) com bit 1 (esquerda) em B
        ld a,b
        rrca                ; bit0 -> carry
        ld c,a              ; guardar (bit1 original agora em bit0)
        ld a,b
        and %00000001       ; direita original
        add a,a             ; -> bit1
        ld d,a
        ld a,c
        and %00000001       ; esquerda original -> bit0
        or d
        ld b,a
pnj_go:
        ld a,(padpx)
        ld c,a
        bit 0,b             ; right: +3 px
        jr z,pck_o
        ld a,(pmax)
        cp c
        jr z,pck_o
        jr c,pck_o
        ld a,c
        add a,3
        ld c,a
        ld a,(pmax)
        cp c
        jr nc,pck_o
        ld c,a
pck_o:
        bit 1,b             ; left: -3 px
        jr z,ppmv
        ld a,c
        cp 3
        jr nc,pl_sub
        xor a               ; padpx<3: encostar mesmo a 0 (cobre a coluna 0)
        ld c,a
        jr ppmv
pl_sub: ld a,c
        sub 3
        ld c,a
ppmv:
        ld a,(padpx)
        cp c
        jr z,pp_done
        push bc
        call erase_paddle
        pop bc
        ld a,c
        ld (padpx),a
        rrca
        rrca
        rrca
        and 31
        ld (padx),a
        call draw_paddle
pp_done:

; ---- vento muda de tempos a tempos ----
        ld a,(wind_cnt)
        dec a
        ld (wind_cnt),a
        jr nz,wind_ok
        call rnd
        and 127
        add a,64
        ld (wind_cnt),a
        ld a,(speed)
        cp 4                ; vento so a partir do NIVEL 3
        jr c,wd_calm
        call rnd
        and 3
        cp 3
        jr nz,wd_set
wd_calm:
        xor a
wd_set: ld (wind),a
wind_ok:

; raquete larga a expirar?
        ld a,(wide_t)
        or a
        jr z,wt_ok
        dec a
        ld (wide_t),a
        jr nz,wt_ok
        call erase_paddle
        ld a,3
        ld (pwid),a
        ld a,232
        ld (pmax),a
        call draw_paddle
wt_ok:

; escudo a expirar (dura o dobro da raquete larga)?
        ld hl,(shield_timer)
        ld a,h
        or l
        jr z,sh_ok
        dec hl
        ld (shield_timer),hl
        ld a,h
        or l
        jr nz,sh_ok
        xor a
        ld (shield_active),a
        call draw_paddle    ; repor a cor normal de imediato
sh_ok:
; comandos trocados a expirar (serpente da Medusa)?
        ld hl,(swap_timer)
        ld a,h
        or l
        jr z,sw_ok
        dec hl
        ld (swap_timer),hl
        ld a,h
        or l
        jr nz,sw_ok
        xor a
        ld (ctrl_swap),a    ; comandos voltam ao normal
sw_ok:
        ld a,(tick)
        and 1
        jr z,common          ; frame par: so a raquete mexeu, sem queda

fall_frame:
        call move_items
        call draw_paddle    ; repara a raquete
        ld a,(gover)
        or a
        jp nz,game_over

common:
        ld a,(boss_type)
        cp 1
        jr nz,cm_c2
        call boss_step      ; Zeus
        jr cm_spawn
cm_c2:  cp 2
        jr nz,cm_c3
        call cronos_step    ; Cronos
        jr cm_spawn
cm_c3:  cp 3
        jr nz,cm_c0
        call medusa_step    ; Medusa
        jr cm_spawn
cm_c0:
; --- sem boss ativo: verificar se ha um pendente (transicao suave) ---
        ld a,(boss_pending)
        or a
        jr z,cm_spawn       ; nada pendente: jogo normal
; ha um boss pendente: nao criar objetos novos e esperar que o ecra esvazie
        call items_on_screen
        or a
        jr nz,cm_refresh    ; ainda ha objetos a cair: deixa-los terminar
; ecra limpo: arrancar o boss agora
        xor a
        ld (boss_pending),a
        call boss_start
        jr cm_refresh
cm_spawn:
        call try_spawn
cm_refresh:
        call refresh_items
        jp main

; conta objetos ativos (itens a cair + rochas). Devolve A=0 se ecra limpo.
items_on_screen:
        ld ix,items
        ld b,NITEMS
        ld c,0
ios_l:  ld a,(ix+0)
        or a
        jr z,ios_n
        inc c
ios_n:  ld de,ISIZE
        add ix,de
        djnz ios_l
        ld a,(rock_active)
        or a
        jr z,ios_done
        inc c
ios_done:
        ld a,c
        ret

; ================= pausa =================
check_pause:
        ld a,$7F
        in a,($FE)
        bit 0,a
        ret nz
        call music_off      ; silencio durante a pausa
cp1:    ld a,$7F
        in a,($FE)
        bit 0,a
        jr z,cp1
        xor a
        ld (pause_sel),a
        call draw_pause_menu
        call redraw_pause_cursor
cpm_loop:
; esperar que O, P e ESPACO estejam TODOS soltos antes de aceitar
; a proxima tecla (evita leituras inconsistentes de teclas coladas)
cpm_wnone:
        halt
        ld a,$DF
        in a,($FE)
        cpl
        and 3
        ld b,a
        ld a,$7F
        in a,($FE)
        cpl
        and 1
        or b
        jr nz,cpm_wnone
; esperar por uma tecla nova (O, P ou ESPACO)
cpm_wkey:
        halt
        ld a,$DF
        in a,($FE)
        cpl
        and 3
        ld b,a              ; bit0=P(baixo) bit1=O(cima)
        ld a,$7F
        in a,($FE)
        cpl
        and 1
        ld c,a              ; C: espaco premido?
        ld a,b
        or c
        jr z,cpm_wkey
; O (cima)
        ld a,b
        and 2
        jr z,cpm_chkp
        ld a,(pause_sel)
        or a
        jr z,cpm_loop
        dec a
        ld (pause_sel),a
        call redraw_pause_cursor
        jr cpm_loop
cpm_chkp:
; P (baixo)
        ld a,b
        and 1
        jr z,cpm_chksp
        ld a,(pause_sel)
        cp 2
        jr z,cpm_loop
        inc a
        ld (pause_sel),a
        call redraw_pause_cursor
        jr cpm_loop
cpm_chksp:
; ESPACO: confirmar a opcao selecionada
        call erase_pause_menu
        ld a,(pause_sel)
        or a
        jr z,cpm_done
        cp 1
        jr z,cpm_restart
        call CLS
        ld a,2
        call CHAN_OPEN
        jp title
cpm_restart:
        jp game_init
cpm_done:
cpm_rel: ld a,$7F
        in a,($FE)
        bit 0,a
        jr z,cpm_rel
        ret

draw_pause_menu:
        ld hl,pm_paused
        call print_str
        ld hl,pm_continue
        call print_str
        ld hl,pm_restart
        call print_str
        ld hl,pm_title
        call print_str
        ret

; apaga o cursor das 3 linhas e volta a desenhar so na linha selecionada
redraw_pause_cursor:
        ld b,0
rpc_l:  push bc
        ld a,22
        rst 16
        pop bc
        push bc
        ld a,10
        add a,b
        rst 16
        ld a,2
        rst 16
        ld a,' '
        rst 16
        pop bc
        inc b
        ld a,b
        cp 3
        jr nz,rpc_l
        ld a,(pause_sel)
        ld b,a
        ld a,22
        rst 16
        ld a,10
        add a,b
        rst 16
        ld a,2
        rst 16
        ld a,'>'
        rst 16
        ret

erase_pause_menu:
        ld b,9
epm_row:
        push bc
        ld a,22
        rst 16
        pop bc
        push bc
        ld a,b
        rst 16
        xor a
        rst 16
        ld c,20
epm_col:
        push bc
        ld a,' '
        rst 16
        pop bc
        dec c
        jr nz,epm_col
        pop bc
        inc b
        ld a,b
        cp 13
        jr nz,epm_row
        ret

; ================= motor de sprites =================
pix_addr:
        ld a,b
        and 7
        ld l,a
        ld a,b
        rrca
        rrca
        rrca
        and $18
        or l
        or $40
        ld h,a
        ld a,b
        rlca
        rlca
        and $E0
        or c
        ld l,a
        ret

spr_put:
        push bc
        ld a,8
sp_l:   push af
        ld a,b
        cp Y_MIN
        jr c,sp_skip
        cp Y_MAX
        jr nc,sp_skip
        push de
        call pix_addr
        pop de
        ld a,b
        cp Y_OVER           ; dentro da zona da raquete?
        ld a,(de)
        jr c,sp_st
        or (hl)             ; OR: o objeto funde-se com a raquete
sp_st:  ld (hl),a
sp_skip:
        inc de
        inc b
        pop af
        dec a
        jr nz,sp_l
        pop bc
        ret

spr_clr:
        push bc
        ld a,8
sc_l:   push af
        ld a,b
        cp Y_MIN
        jr c,sc_skip
        cp Y_MAX
        jr nc,sc_skip
        call pix_addr
        ld (hl),0
sc_skip:
        inc b
        pop af
        dec a
        jr nz,sc_l
        pop bc
        ret

spr_attr:
        push bc
        ld a,b
        rrca
        rrca
        rrca
        and $1F
        ld d,a
        cp 1
        jr c,sa_done
        cp 21
        jr nc,sa_done
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        or l
        ld l,a
        ld a,h
        or $58
        ld h,a
        ld (hl),e
        ld a,b
        and 7
        jr z,sa_done
        ld a,d
        cp 20
        jr nc,sa_done
        ld bc,32
        add hl,bc
        ld (hl),e
sa_done:
        pop bc
        ret

item_draw:
        ld a,(ix+0)
        cp T_STAR
        jr nz,id2
        ld de,(anim_ptr)
        ld a,AT_STAR
        jr id_go
id2:    cp T_GOLD
        jr nz,id3
        ld de,spr_gold
        ld a,(gold_at)
        jr id_go
id3:    cp T_BOMB
        jr nz,id3b
        ld de,spr_bomb
        ld a,AT_BOMB
        jr id_go
id3b:   cp T_BOLT
        jr nz,id3c
        ld de,spr_bolt
        ld a,$45            ; cyan bright
        jr id_go
id3c:   cp T_WIDE
        jr nz,id3d
        ld de,spr_wide
        ld a,$44            ; verde: raquete larga!
        jr id_go
id3d:   cp T_SHIELD
        jr nz,id3e
        ld de,spr_bubble
        ld a,$41            ; azul brilhante: bolha de escudo
        jr id_go
id3e:   cp T_UFOF
        jr nz,id3f
        ld de,spr_gold
        ld a,$45            ; cyan brilhante: ovni
        jr id_go
id3f:   cp T_SNAKE
        jr nz,id4
        ld de,spr_snake
        ld a,$44            ; verde: serpente da Medusa
        jr id_go
id4:    ld de,spr_heart
        ld a,AT_HEART
id_go:
        ld b,(ix+2)
        ld c,(ix+1)
        push af
        call spr_put
        pop af
        ld e,a
        call spr_attr
        ret

refresh_items:
        ld ix,items
        ld b,NITEMS
ri_loop:
        push bc
        ld a,(ix+0)
        or a
        jr z,ri_next
        push ix
        call item_draw
        pop ix
ri_next:
        ld de,ISIZE
        add ix,de
        pop bc
        djnz ri_loop
        ret

; limpa todos os objetos a cair (ecra + tabela) e faz uma pausa para
; darem a sensacao de "desaparecer" antes/depois de um boss.
clear_falling_items:
        ld ix,items
        ld b,NITEMS
cfi_loop:
        push bc
        ld a,(ix+0)
        or a
        jr z,cfi_next
        ld b,(ix+2)         ; y (linha de pixels)
        ld c,(ix+1)         ; x (coluna)
        call spr_clr
        xor a
        ld (ix+0),a         ; libertar o slot
cfi_next:
        ld de,ISIZE
        add ix,de
        pop bc
        djnz cfi_loop
; limpar tambem os blocos de rocha: apagar do ecra E desativar
        ld a,(rock_active)
        or a
        jr z,cfi_norock
        ld ix,rock_data
        ld b,3
cfi_rloop:
        push bc
        ld a,(ix+0)
        or a
        jr z,cfi_rnext
        ld c,(ix+1)         ; coluna
        ld b,(ix+2)         ; linha
        call spr_clr        ; apagar o bloco do ecra
cfi_rnext:
        xor a
        ld (ix+0),a         ; desativar o bloco
        ld de,3
        add ix,de
        pop bc
        djnz cfi_rloop
        xor a
        ld (rock_active),a
cfi_norock:
; pausa curta para "assentar" (~0.4s)
        ld b,20
cfi_pause:
        halt
        djnz cfi_pause
        ret

; ================= movimento e colisoes =================
move_items:
        ld ix,items
        ld b,NITEMS
mi_loop:
        push bc
        ld a,(ix+0)
        or a
        jp z,mi_next
        ld b,(ix+2)
        ld c,(ix+1)
        call spr_clr
; ---- vento: desvio lateral ocasional ----
        ld a,(rock_active)
        or a
        jr nz,no_wind       ; com meteoritos a cair, sem vento
        ld a,(boss_type)
        cp 2
        jr z,no_wind        ; durante o Cronos, sem vento
        ld a,(wind)
        or a
        jr z,no_wind
        call rnd
        and 7
        jr nz,no_wind
        ld a,(wind)
        cp 1
        jr nz,wd_esq
        ld a,(ix+1)
        cp 30               ; nao passar da coluna 30 (deixa margem p/ apanhar)
        jr nc,no_wind
        inc (ix+1)
        jr no_wind
wd_esq: ld a,(ix+1)
        cp 2                ; nao passar da coluna 1 (deixa margem p/ apanhar)
        jr c,no_wind
        dec (ix+1)
no_wind:
; ---- queda com a velocidade PROPRIA do objeto ----
        ld a,(ix+3)
        add a,(ix+2)
        ld (ix+2),a
        cp Y_CATCH
        jp c,mi_next
; ALTURA DA RAQUETE: apanha se alinhado, falha se ao lado
        ld a,(padx)
        ld d,a
        ld a,(ix+1)
        sub d
        jp c,at_floor
        ld e,a
        ld a,(padpx)
        and 7
        jr z,cw0
        ld a,1
cw0:    ld hl,pwid
        add a,(hl)
        ld d,a
        ld a,e
        cp d
        jp nc,at_floor
        ld a,(ix+0)
        ld e,a
        ld (ix+0),0
        ld a,(ix+1)
        ld (boom_x),a
        ld a,e
        cp T_STAR
        jr nz,cg
        push ix
        call do_catch
        pop ix
        jp mi_next
cg:     cp T_GOLD
        jr nz,cb
        push ix
        call do_gold
        pop ix
        jp mi_next
cb:     cp T_BOMB
        jr nz,cl
        push ix
        call do_bomb
        pop ix
        jp mi_next
cl:     cp T_BOLT
        jr nz,cw
        push ix
        call do_bolt
        pop ix
        jp mi_next
cw:     cp T_WIDE
        jr nz,cs
        push ix
        call do_wide
        pop ix
        jp mi_next
cs:     cp T_SHIELD
        jr nz,cu
        push ix
        call do_shield
        pop ix
        jp mi_next
cu:     cp T_UFOF
        jr nz,csn
        push ix
        call do_ufo
        pop ix
        jp mi_next
csn:    cp T_SNAKE
        jr nz,ch
        push ix
        call do_snake
        pop ix
        jp mi_next
ch:     push ix
        call do_heart
        pop ix
        jp mi_next
at_floor:
        ld a,(ix+0)
        ld e,a
        ld (ix+0),0
        ld a,e
        cp T_STAR
        jp nz,mi_next
        push ix
        call do_miss
        pop ix
mi_next:
        ld de,ISIZE
        add ix,de
        pop bc
        dec b
        jp nz,mi_loop       ; corpo demasiado grande para djnz
        ret

; ---- pontuacao ----
do_catch:
        call sparkle
        ld a,(combo)
        cp 99
        jr z,dc_bc
        inc a
        ld (combo),a
        ld hl,best_combo
        cp (hl)
        jr c,dc_bc
        ld (hl),a
dc_bc:  call catch_beep     ; som da apanha, com tom conforme o combo
        ld a,(combo)
; multiplicador por patamar: <3 = x1, 3-9 = x2, 10-19 = x3, 20+ = x4
        cp 20
        jr nc,dc_x4
        cp 10
        jr nc,dc_x3
        cp 3
        jr nc,dc_x2
; x1: pontos base
        ld a,(speed)
        dec a
        ld b,a
        jp add_pts
dc_x2:  ld a,(speed)
        dec a
        sla a
        ld b,a
        jp add_pts
dc_x3:  ld a,(speed)
        dec a
        ld c,a
        sla a
        add a,c             ; base*3
        ld b,a
        jp add_pts
dc_x4:  ld a,(speed)
        dec a
        sla a
        sla a               ; base*4
        ld b,a
        jp add_pts
do_gold:
        call sparkle
        ld a,7
        out ($FE),a         ; clarao branco rapido
        halt
        ld a,(cur_border)
        out ($FE),a
        ld a,(combo)
        cp 99
        jr z,dg_cmb
        inc a
        ld (combo),a
        ld hl,best_combo
        cp (hl)
        jr c,dg_cmb
        ld (hl),a
dg_cmb: ld hl,$00D0          ; ouro: agudo brilhante
        ld de,$0050
        call play_fx
        ld b,GOLD_PTS       ; a dourada vale sempre GOLD_PTS, sem duplicar por combo
        jp add_pts
; testa se a pontuacao cruzou algum marco (100/500/1000) neste passo
check_milestone:
        push hl
        push de
        ld bc,1500
        call cm_test
        pop de
        pop hl
        ret nz
        push hl
        push de
        ld bc,1000
        call cm_test
        pop de
        pop hl
        ret nz
        push hl
        push de
        ld bc,500
        call cm_test
        pop de
        pop hl
        ret nz
        push hl
        push de
        ld bc,100
        call cm_test
        pop de
        pop hl
        ret

cm_test:
        push hl
        or a
        sbc hl,bc
        pop hl
        jr c,cm_no
        ex de,hl
        or a
        sbc hl,bc
        ex de,hl
        jr nc,cm_no
        ld a,c
        cp 220              ; 1500 = 0x05DC, byte baixo 220
        jr nz,cm_1000
        ld hl,melody_1000
        ld de,mile_1500
        jr cm_play
cm_1000:
        ld a,c
        cp 232
        jr nz,cm_5
        ld hl,melody_1000
        ld de,mile_1000
        jr cm_play
cm_5:   ld a,c
        cp 244
        jr nz,cm_1
        ld hl,melody_500
        ld de,mile_500
        jr cm_play
cm_1:   ld hl,melody_100
        ld de,mile_100
cm_play:
        ld (mile_ptr),de
        call play_tune
        ld hl,(mile_ptr)
        call show_banner
        ld a,1
        or a
        ret
cm_no:  xor a
        ret

; ---- banner temporario (mensagens no meio do ecra) ----
show_banner:
        call print_str
        ld a,60
        ld (banner_timer),a
        ret

banner_step:
        ld a,(banner_timer)
        or a
        ret z
        dec a
        ld (banner_timer),a
        ret nz
        ld hl,banner_clear
        call print_str
        ret

check_hiscore_beat:
        ld a,(hs_beaten)
        or a
        ret nz
        push hl
        ld de,(hstab+3)
        or a
        sbc hl,de
        pop hl
        ret c
        ret z
        ld a,1
        ld (hs_beaten),a
        call hiscore_flash
        ret

hiscore_flash:
        ld b,8
hf_l:   push bc
        ld a,b
        and 7
        out ($FE),a
        ld hl,$0040
        ld de,$0020
        call BEEPER
        pop bc
        djnz hf_l
        ld a,(cur_border)
        out ($FE),a
        ret

add_pts:
        ld hl,(score)
        push hl
        ld d,0
        ld e,b
        add hl,de
        ld (score),hl
        pop de
        push bc              ; check_milestone usa BC; preservar os pontos (B)
        call check_milestone
        call check_hiscore_beat
        pop bc
; --- boss quando a pontuacao atinge next_boss (200, 400, depois +100) ---
        ld hl,(score)
        ld de,(next_boss)
        or a
        sbc hl,de
        jr c,ap_10          ; ainda nao chegou ao proximo limiar
        ld a,1
        ld (boss_pending),a ; marcar: o boss entra assim que o ecra estiver limpo
        call advance_next_boss
ap_10:
        ld a,(score10)
        add a,b
        cp 200              ; novo nivel a cada 200 pontos
        jr c,ap_keep
        sub 200
        ld (score10),a
        ld a,(speed)
        cp SPEED_MAX
        jr z,ap_snd
        inc a
        ld (speed),a
        sub 2                ; novo_speed-2 = indice do nivel na tabela (0-4)
        ld hl,border_tab
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ld (cur_border),a
        out ($FE),a
        ld hl,$0080
        ld de,$0080
        call play_fx
        jr ap_hud
ap_keep:
        ld (score10),a
ap_snd:
        ld hl,$0100
        ld de,$0040
        call play_fx
ap_hud:
        call draw_hud
        ret

do_miss:
        ld a,(shield_active)
        or a
        jr z,dm_noshield
        call shield_deflect_fx  ; escudo aguenta: sem quebrar nem tirar vida
        ret
dm_noshield:
        xor a
        ld (combo),a        ; combo quebrado
        ld a,(lives)
        dec a
        ld (lives),a
        push af
        ld hl,$0600
        ld de,$0080
        call play_fx
        call start_miss_fx
        call border_flash   ; pausa curta + bordas a piscar, tal como ao ser atingido
        pop af
        jr nz,dm_hud
        ld a,1
        ld (gover),a
dm_hud:
        call draw_hud
        ret

do_bolt:                    ; raio: explosao cyan
        ld a,5
        ld (boom_bd),a
        jp do_hit
do_bomb:                    ; bomba: explosao vermelha
        ld a,2
        ld (boom_bd),a
        jp do_hit

; efeito de acerto (explosao + raquete a piscar) SEM bloquear o jogo:
; em vez de HALT, avanca 1 passo por frame atraves de hit_fx_step,
; chamado no ciclo principal -- o resto do jogo continua a mexer-se.
HITFX_EXPLODE_STEPS equ 10
HITFX_BLINK_STEPS equ 4

start_hit_fx:
        ld a,(hit_active)
        or a
        ret nz              ; ja ha uma animacao em curso: nao reiniciar
        ld a,1
        ld (hit_active),a
        xor a
        ld (hit_phase),a
        ld (hit_subcnt),a
        ld a,(boom_x)
        ld (hit_x),a
        ret

; pequena pausa (~0.12s) com as bordas a piscar em vermelho/branco:
; da um "solavanco" visual ao ser atingido ou ao falhar uma estrela
border_flash:
        ld b,6
bf_l:   push bc
        ld a,b
        and 1
        jr z,bf_c1
        ld a,2              ; vermelho
        jr bf_out
bf_c1:  ld a,7              ; branco
bf_out: out ($FE),a
        halt
        pop bc
        djnz bf_l
        ld a,(cur_border)
        out ($FE),a
        ret

; tal como start_hit_fx, mas sem fase de explosao (usado em falhas
; simples, que so fazem a raquete piscar, sem bola de fogo)
start_miss_fx:
        ld a,(hit_active)
        or a
        ret nz              ; ja ha uma animacao em curso: nao reiniciar
        ld a,1
        ld (hit_active),a
        ld a,HITFX_EXPLODE_STEPS
        ld (hit_phase),a
        xor a
        ld (hit_subcnt),a
        ret

hit_fx_step:
        ld a,(hit_active)
        or a
        ret z
        ld a,(hit_subcnt)
        inc a
        ld (hit_subcnt),a
        cp 2                ; muda de visual a cada 2 frames
        ret c
        xor a
        ld (hit_subcnt),a
        ld a,(hit_phase)
        cp HITFX_EXPLODE_STEPS
        jr nc,hf_blink_phase
; --- passo da animacao de explosao ---
        ld a,(boom_bd)
        out ($FE),a
        ld a,(hit_phase)
        and 1
        jr z,hf_f1
        ld de,spr_boom2
        ld a,$42
        jr hf_dd
hf_f1:  ld de,spr_boom1
        ld a,$46
hf_dd:  push af
        ld a,(hit_x)
        ld c,a
        ld b,BOOM_Y
        call spr_put
        pop af
        ld e,a
        call spr_attr
        ld a,(hit_phase)
        inc a
        ld (hit_phase),a
        cp HITFX_EXPLODE_STEPS
        ret nz
; explosao terminou: limpar e repor a borda
        ld a,(hit_x)
        ld c,a
        ld b,BOOM_Y
        call spr_clr
        ld a,(cur_border)
        out ($FE),a
        ret
hf_blink_phase:
; --- passo da raquete a piscar ---
        ld a,(hit_phase)
        sub HITFX_EXPLODE_STEPS
        and 1
        jr nz,hf_draw
        call erase_paddle
        jr hf_advance
hf_draw:
        call draw_paddle
hf_advance:
        ld a,(hit_phase)
        inc a
        ld (hit_phase),a
        cp HITFX_EXPLODE_STEPS+HITFX_BLINK_STEPS*2
        ret nz
        xor a
        ld (hit_active),a
        call draw_paddle   ; garantir que fica bem desenhada no fim
        ret

; serpente da Medusa: perde 1 vida E fica com os comandos trocados
; (durante o mesmo tempo que a invulnerabilidade da bolha = 500 frames).
; Se o escudo estiver ativo, repele sem dano nem inversao.
do_snake:
        ld a,(shield_active)
        or a
        jr z,ds_hit
        call shield_deflect_fx
        ret
ds_hit:
        ld a,1
        ld (ctrl_swap),a        ; comandos trocados
        ld hl,500
        ld (swap_timer),hl      ; mesma duracao da bolha
        call do_hit             ; perde 1 vida (com efeito visual/sonoro)
        ret

do_hit:
        ld a,(shield_active)
        or a
        jr z,dh_noshield
        call shield_deflect_fx  ; escudo aguenta: repele sem quebrar nem tirar vida
        ret
dh_noshield:
        xor a
        ld (combo),a
        ld a,(lives)
        dec a
        ld (lives),a
        push af
        call start_hit_fx
        ld hl,$0C00
        ld de,$00C0
        call play_fx
        ld hl,$0800
        ld de,$0080
        call play_fx
        call border_flash   ; pausa curta + bordas a piscar
        pop af
        jr nz,db_hud
        ld a,1
        ld (gover),a
db_hud:
        call draw_hud
        ret

; escudo consumido: som distinto e clarao azul rapido, mas sem perder vida
shield_break_fx:
        ld hl,0
        ld (shield_timer),hl
        ld a,1
        out ($FE),a         ; clarao azul rapido
        ld hl,$0300
        ld de,$0060
        call play_fx
        halt
        ld a,(cur_border)
        out ($FE),a
        call draw_hud
        ret

; escudo aguenta um acerto: clarao azul curto, mas NAO quebra nem tira vida
; (fica ativo ate o shield_timer expirar naturalmente)
shield_deflect_fx:
        ld a,1
        out ($FE),a         ; clarao azul rapido
        ld hl,$0300
        ld de,$0040
        call play_fx
        halt
        ld a,(cur_border)
        out ($FE),a
        ret

do_heart:
        call sparkle
        ld a,(lives)
        cp 5
        jr z,dh_full        ; vidas cheias: converte o coracao em 20 pontos
        inc a
        ld (lives),a
        jr dh_snd
dh_full:
        ld b,GOLD_PTS       ; 20 pontos por coracao "extra" (vidas ja no maximo)
        call add_pts
dh_snd:
        ld hl,$0280         ; coracao: par de tons quentes ascendentes
        ld de,$0060
        call play_fx
        ld hl,$01C0
        ld de,$0080
        call play_fx
        call draw_hud
        ret

; brilho de apanho junto a raquete
sparkle:
        ld b,4
sk_l:   push bc
        ld a,b
        and 1
        jr z,sk1
        ld de,spr_boom2
        jr sk2
sk1:    ld de,spr_star2
sk2:    ld a,(boom_x)
        ld c,a
        ld b,SPARK_Y
        call spr_put
        ld e,$46
        call spr_attr
        halt
        halt
        pop bc
        djnz sk_l
        ld a,(boom_x)
        ld c,a
        ld b,SPARK_Y
        call spr_clr
        call draw_paddle
        ret

; ================= despachante de bosses =================
; escolhe o proximo boss conforme boss_rotation e avanca a rotacao.
; Fase 1: so o Zeus esta implementado; Cronos/Medusa entram nas fases seguintes.
boss_start:
        ld a,(boss_type)
        or a
        ret nz              ; ja ha um boss ativo: nao duplicar
        ld a,(boss_rotation)
        cp 1
        jr z,bstart_cronos
        cp 2
        jr z,bstart_medusa
; --- Zeus (rotacao 0) ---
        call advance_rotation
        jp zeus_start
bstart_cronos:
        call advance_rotation
        jp cronos_start
bstart_medusa:
        call advance_rotation
        jp medusa_start

; avanca a rotacao 0->1->2->0
advance_rotation:
        ld a,(boss_rotation)
        inc a
        cp 3
        jr c,ar_ok
        xor a
ar_ok:  ld (boss_rotation),a
        ret

; avanca o limiar do proximo boss: 200 -> 400, depois +100 (500,600,...)
advance_next_boss:
        ld hl,(next_boss)
        ld de,200
        add hl,de            ; proximo boss +200 (200, 400, 600, 800...)
        ld (next_boss),hl
        ret

; --- Cronos (rotacao 1): acelera a queda, so estrelas, ~8 segundos ---
; oportunidade de combo: velocidade +2, zero obstaculos.
cronos_start:
        ld a,(boss_type)
        or a
        ret nz
        ld a,2
        ld (boss_type),a    ; 2 = Cronos ativo
        ; Cronos corre a velocidade normal do nivel (sem acelerar):
        ; a "presenca" vem da ampulheta e de so cairem estrelas
        ld hl,150           ; tempo de espera apos as 5 estrelas (~3s)
        ld (boss_timer),hl  ; (so conta depois de largar a 5a estrela)
        ld a,1
        ld (hour_x),a       ; comeca perto da esquerda
        ld (hour_dir),a     ; a mover-se para a direita
        xor a
        ld (hour_spawn),a
        ld (hour_count),a   ; ainda nao largou estrelas
        call cronos_warning
        call draw_hourglass
        ret
; --- Medusa (rotacao 2) --- FASE 3: stub, comporta-se como Zeus ---
; ================= MEDUSA (boss 3) =================
; anda no topo como o Zeus (persegue/erra), tamanho 3x2, lanca serpentes.
; so caem serpentes; ao acertarem: perde 1 vida + comandos trocados.
medusa_start:
        ld a,(boss_type)
        or a
        ret nz
        ld a,3
        ld (boss_type),a    ; 3 = Medusa ativa
        ld a,(lives)
        ld (boss_lv),a
        ld a,20             ; lanca 20 serpentes e retira-se
        ld (snake_cnt),a
        xor a
        ld (boss_frm),a
        call rnd
        and 31
        cp 27
        jr c,med_xok
        ld a,27
med_xok: ld (medusa_x),a
        call medusa_warning
        call draw_medusa
        ret

; aviso da Medusa: bordas a pulsar verde/branco
medusa_warning:
        ld hl,msg_medusa
        call print_str
        ld b,16
mw_l:   push bc
        ld a,b
        and 1
        jr z,mw_c1
        ld a,4              ; verde
        jr mw_out
mw_c1:  ld a,7              ; branco
mw_out: out ($FE),a
        call warn_halt
        call warn_halt
        call warn_halt
        call warn_halt
        pop bc
        djnz mw_l
        ld a,(cur_border)
        out ($FE),a
        ld hl,msg_medusa_clr
        call print_str
        ret

; passo da Medusa: move-se (persegue/erra) e lanca serpentes
medusa_step:
        ld a,(boss_frm)
        inc a
        ld (boss_frm),a
        and 7
        jr nz,med_throw     ; so decide mover a cada 8 frames
        call rnd
        and 3
        jr z,med_throw      ; 25%: hesita
        cp 1
        jr z,med_rnd        ; 25%: passo errante
; 50%: persegue a raquete
        ld a,(medusa_x)
        ld b,a
        ld a,(padx)
        cp b
        jr z,med_throw
        jr nc,med_dir
        jr med_esq
med_rnd: call rnd
        and 1
        jr z,med_esq
med_dir: ld a,(medusa_x)
        cp 29
        jr nc,med_throw
        call erase_medusa
        ld a,(medusa_x)
        inc a
        ld (medusa_x),a
        call draw_medusa
        jr med_throw
med_esq: ld a,(medusa_x)
        or a
        jr z,med_throw
        call erase_medusa
        ld a,(medusa_x)
        dec a
        ld (medusa_x),a
        call draw_medusa
med_throw:
        ld a,(boss_frm)
        and 31              ; uma serpente a cada 32 frames
        ret nz
; largar uma serpente da coluna da Medusa (procura slot livre)
        ld ix,items
        ld b,NITEMS
med_sl: ld a,(ix+0)
        or a
        jr z,med_sok
        ld de,ISIZE
        add ix,de
        djnz med_sl
        jr med_dec          ; sem slot: nao larga desta vez
med_sok:
        ld (ix+0),T_SNAKE
        ld a,(medusa_x)
        inc a               ; da zona central da Medusa
        ld (ix+1),a
        ld a,32
        ld (ix+2),a
        ld a,(speed)
        ld (ix+3),a
; contar serpentes lancadas
        ld a,(snake_cnt)
        dec a
        ld (snake_cnt),a
        ret nz
        jr med_end
med_dec:
        ret
med_end:
; todas as serpentes lancadas: Medusa retira-se
        call erase_medusa
        xor a
        ld (boss_type),a    ; as serpentes restantes terminam a queda
        ret

; desenhar a Medusa 3x2 na coluna medusa_x (via spr_put, como a ampulheta)
draw_medusa:
        ld a,(medusa_x)
        ld c,a
        ld de,spr_med_tl
        ld b,16
        call spr_put
        ld a,(medusa_x)
        inc a
        ld c,a
        ld de,spr_med_tm
        ld b,16
        call spr_put
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld de,spr_med_tr
        ld b,16
        call spr_put
        ld a,(medusa_x)
        ld c,a
        ld de,spr_med_bl
        ld b,24
        call spr_put
        ld a,(medusa_x)
        inc a
        ld c,a
        ld de,spr_med_bm
        ld b,24
        call spr_put
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld de,spr_med_br
        ld b,24
        call spr_put
; atributos verdes nas 6 celulas
        ld a,(medusa_x)
        ld c,a
        ld b,16
        ld e,$44
        call spr_attr
        ld a,(medusa_x)
        inc a
        ld c,a
        ld b,16
        ld e,$44
        call spr_attr
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld b,16
        ld e,$44
        call spr_attr
        ld a,(medusa_x)
        ld c,a
        ld b,24
        ld e,$44
        call spr_attr
        ld a,(medusa_x)
        inc a
        ld c,a
        ld b,24
        ld e,$44
        call spr_attr
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld b,24
        ld e,$44
        call spr_attr
        ret

; apagar a Medusa (limpa as 6 celulas)
erase_medusa:
        ld a,(medusa_x)
        ld c,a
        ld b,16
        call spr_clr
        ld a,(medusa_x)
        inc a
        ld c,a
        ld b,16
        call spr_clr
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld b,16
        call spr_clr
        ld a,(medusa_x)
        ld c,a
        ld b,24
        call spr_clr
        ld a,(medusa_x)
        inc a
        ld c,a
        ld b,24
        call spr_clr
        ld a,(medusa_x)
        add a,2
        ld c,a
        ld b,24
        call spr_clr
        ret

; aviso do Cronos: bordas a pulsar em cyan/branco (identidade propria)
cronos_warning:
        ld hl,msg_cronos
        call print_str
        ld b,16             ; mais relampagos: aviso mais demorado (~1.3s)
cw_l:   push bc
        ld a,b
        and 1
        jr z,cw_c1
        ld a,5              ; cyan
        jr cw_out
cw_c1:  ld a,7              ; branco
cw_out: out ($FE),a
        call warn_halt
        call warn_halt
        call warn_halt
        call warn_halt      ; 4 frames por relampago (mais lento de ler)
        pop bc
        djnz cw_l
        ld a,(cur_border)
        out ($FE),a
        ld hl,msg_cronos_clr
        call print_str
        ret

; ampulheta desenhada no topo (linha de caracteres 2), lado esquerdo
draw_hourglass:
; --- linha de cima (y=16): TL em hour_x, TR em hour_x+1 ---
        ld de,spr_hour_tl
        ld a,(hour_x)
        ld c,a
        ld b,16
        call spr_put
        ld de,spr_hour_tr
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,16
        call spr_put
; --- linha de baixo (y=24): BL em hour_x, BR em hour_x+1 ---
        ld de,spr_hour_bl
        ld a,(hour_x)
        ld c,a
        ld b,24
        call spr_put
        ld de,spr_hour_br
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,24
        call spr_put
; --- atributos cyan brilhante nas 4 celulas ---
        ld a,(hour_x)
        ld c,a
        ld b,16
        ld e,$45
        call spr_attr
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,16
        ld e,$45
        call spr_attr
        ld a,(hour_x)
        ld c,a
        ld b,24
        ld e,$45
        call spr_attr
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,24
        ld e,$45
        call spr_attr
        ret

erase_hourglass:
        ld a,(hour_x)
        ld c,a
        ld b,16
        call spr_clr
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,16
        call spr_clr
        ld a,(hour_x)
        ld c,a
        ld b,24
        call spr_clr
        ld a,(hour_x)
        inc a
        ld c,a
        ld b,24
        call spr_clr
        ret

; passo do Cronos: conta o tempo; ao esgotar, restaura a velocidade
cronos_step:
; --- mover a ampulheta a cada 4 frames (metade da velocidade) ---
        ld a,(tick)
        and 3
        jr nz,cst_spawn     ; so move 1 em cada 4 frames
        call erase_hourglass
        ld a,(hour_dir)
        or a
        jr z,cst_left
        ld a,(hour_x)       ; a ir para a direita
        cp 30
        jr nc,cst_flipL
        inc a
        ld (hour_x),a
        jr cst_drawn
cst_flipL:
        xor a
        ld (hour_dir),a
        jr cst_drawn
cst_left:
        ld a,(hour_x)
        or a
        jr z,cst_flipR
        dec a
        ld (hour_x),a
        jr cst_drawn
cst_flipR:
        ld a,1
        ld (hour_dir),a
cst_drawn:
        call draw_hourglass
cst_spawn:
; --- fase 1: largar exatamente 10 estrelas (uma a cada ~45 frames) ---
        ld a,(hour_count)
        cp 10
        jr nc,cst_wait      ; ja largou as 10: passar a fase de espera
        ld a,(hour_spawn)
        inc a
        ld (hour_spawn),a
        cp 45
        jr c,cst_done       ; ainda nao e altura de largar
        call drop_star_from_hour
        jr c,cst_done       ; nao havia slot livre: tentar no proximo frame
        xor a               ; largou: reiniciar contador de intervalo
        ld (hour_spawn),a
        ld a,(hour_count)
        inc a
        ld (hour_count),a
        jr cst_done
cst_wait:
; --- fase 2: 5 estrelas largadas; esperar que a ultima chegue ao fundo ---
        ld hl,(boss_timer)
        dec hl
        ld (boss_timer),hl
        ld a,h
        or l
        jr nz,cst_done
; espera esgotada: Cronos retira-se
        call erase_hourglass
        xor a
        ld (boss_type),a    ; as estrelas restantes terminam a queda naturalmente
        ret
cst_done:
        ret

; larga uma estrela na coluna atual da ampulheta (procura um slot livre)
; carry set = nao havia slot; carry limpo = largou
drop_star_from_hour:
        ld ix,items
        ld b,NITEMS
dsh_l:  ld a,(ix+0)
        or a
        jr z,dsh_ok
        ld de,ISIZE
        add ix,de
        djnz dsh_l
        scf                 ; sem slots livres: carry set (nao largou)
        ret
dsh_ok:
        ld (ix+0),T_STAR
        ld a,(hour_x)
        ld (ix+1),a
        ld a,32             ; logo abaixo da ampulheta 2x2 (y=16..31)
        ld (ix+2),a
        ld a,(speed)
        ld (ix+3),a
        or a                ; carry limpo: largou com sucesso
        ret

; ================= ZEUS (boss) =================
; aparece a cada 60 pontos, persegue a raquete e
; dispara 25 raios; os objetos normais suspendem-se
zeus_start:
        ld a,(bolt_cnt)
        or a
        ret nz              ; Zeus ja esta ativo: nao duplicar!
        ld a,1
        ld (boss_type),a    ; 1 = Zeus ativo
        ld a,(lives)
        ld (boss_lv),a
        ld a,(zeus_count)
        cp 6
        jr nc,bs_zok
        inc a
        ld (zeus_count),a
bs_zok: ld a,25             ; 25 raios!
        ld (bolt_cnt),a
        xor a
        ld (boss_frm),a
        call rnd
        and 31
        cp 27
        jr c,bs_xok
        ld a,27
bs_xok: ld (zeus_x),a
        call zeus_warning   ; aviso dramatico antes de o Zeus surgir
        call draw_zeus
        ret

; aviso antes do Zeus: mostra "ZEUS!" a piscar e faz as bordas
; relampejar em amarelo/branco, com um tremor curto -- cria tensao
zeus_warning:
        ld hl,msg_zeus
        call print_str
        ld b,16             ; aviso mais demorado (~1.3s)
zw_l:   push bc
        ld a,b
        and 1
        jr z,zw_c1
        ld a,6              ; amarelo (relampago)
        jr zw_out
zw_c1:  ld a,7              ; branco
zw_out: out ($FE),a
        call warn_halt
        call warn_halt
        call warn_halt
        call warn_halt
        pop bc
        djnz zw_l
        ld a,(cur_border)
        out ($FE),a
        ld hl,msg_zeus_clr  ; apagar a mensagem antes de o Zeus surgir
        call print_str
        ret

; espera um frame mantendo a musica a tocar (nao congela a nota)
warn_halt:
        halt
        call music_step
        ret

boss_step:
        ld a,(boss_frm)
        inc a
        ld (boss_frm),a
        ld b,a
        ld a,(zeus_count)
        or a
        jr z,bz_m0
        dec a
        ld hl,zeus_speed_tab
        ld e,a
        ld d,0
        add hl,de
        ld a,b
        and (hl)
        jr nz,bz_throw
        jr bz_go
bz_m0:  ld a,b
        and 7
        jr nz,bz_throw
bz_go:
        call rnd
        and 3
        jr z,bz_throw       ; 25%: hesita no ar
        cp 1
        jr z,bz_rnd         ; 25%: passo errante
; 50%: persegue a raquete
        ld a,(zeus_x)
        ld b,a
        ld a,(padx)
        cp b
        jr z,bz_throw
        jr nc,bz_dir
        jr bz_esq
bz_rnd: call rnd
        and 1
        jr z,bz_esq
bz_dir: ld a,(zeus_x)
        cp 29
        jr z,bz_throw
        call erase_zeus
        ld a,(zeus_x)
        inc a
        ld (zeus_x),a
        call draw_zeus
        jr bz_throw
bz_esq: ld a,(zeus_x)
        or a
        jr z,bz_throw
        call erase_zeus
        ld a,(zeus_x)
        dec a
        ld (zeus_x),a
        call draw_zeus
bz_throw:
        ld a,(boss_frm)
        and 15              ; um raio a cada 16 frames
        ret nz
        ld ix,items
        ld b,NITEMS
zb_l:   ld a,(ix+0)
        or a
        jr z,zb_ok
        ld de,ISIZE
        add ix,de
        djnz zb_l
        ret
zb_ok:  ld (ix+0),T_BOLT
        ld a,(zeus_x)
        inc a
        ld (ix+1),a
        ld (ix+2),Y_SPAWN
        ld a,(speed)
        add a,3             ; raios sao rapidissimos!
        ld (ix+3),a
; nivel alto: hipotese de um segundo raio lado a lado
        ld a,(speed)
        cp 5
        jr c,zb_single
        call rnd
        and 1
        jr nz,zb_single
        push ix
        ld ix,items
        ld b,NITEMS
zb2_l:  ld a,(ix+0)
        or a
        jr z,zb2_ok
        ld de,ISIZE
        add ix,de
        djnz zb2_l
        jr zb2_done
zb2_ok: ld (ix+0),T_BOLT
        ld a,(zeus_x)
        sub 3
        jr nc,zb2_x
        xor a
zb2_x:  ld (ix+1),a
        ld (ix+2),Y_SPAWN
        ld a,(speed)
        add a,3
        ld (ix+3),a
zb2_done:
        pop ix
zb_single:
        ld a,(bolt_cnt)
        dec a
        ld (bolt_cnt),a
        ret nz
        call erase_zeus     ; 25 raios lancados: Zeus retira-se
        xor a
        ld (boss_type),a    ; os raios restantes terminam a queda naturalmente
        ld a,(boss_lv)
        ld b,a
        ld a,(lives)
        cp b
        ret nz
        ld b,10             ; sobreviveu ileso: +10 pontos!
        jp add_pts

draw_zeus:
        ld a,22
        rst 16
        ld a,1
        rst 16
        ld a,(zeus_x)
        rst 16
        ld a,16
        rst 16
        ld a,7
        rst 16
        ld a,19
        rst 16
        ld a,1
        rst 16
        ld a,ZT_L
        rst 16
        ld a,ZT_M
        rst 16
        ld a,ZT_R
        rst 16
        ld a,22
        rst 16
        ld a,2
        rst 16
        ld a,(zeus_x)
        rst 16
        ld a,ZB_L
        rst 16
        ld a,ZB_M
        rst 16
        ld a,ZB_R
        rst 16
        ret

erase_zeus:
        ld a,22
        rst 16
        ld a,1
        rst 16
        ld a,(zeus_x)
        rst 16
        ld a,' '
        rst 16
        ld a,' '
        rst 16
        ld a,' '
        rst 16
        ld a,22
        rst 16
        ld a,2
        rst 16
        ld a,(zeus_x)
        rst 16
        ld a,' '
        rst 16
        ld a,' '
        rst 16
        ld a,' '
        rst 16
        ret

; power-up: raquete larga por ~5 segundos
do_wide:
        call sparkle
        call erase_paddle
        ld a,5
        ld (pwid),a
        ld a,216
        ld (pmax),a
        ld a,(padpx)
        cp 217
        jr c,dw1
        ld a,216
        ld (padpx),a
dw1:    ld a,(padpx)
        rrca
        rrca
        rrca
        and 31
        ld (padx),a
        call draw_paddle
        ld a,250
        ld (wide_t),a
        ld hl,$0320         ; raquete larga: tom medio-grave
        ld de,$0060
        call play_fx
        ret

; escudo apanhado: protege contra a proxima falha (bomba ou estrela
; perdida), sem stack de mais que 1 (novo escudo so substitui o antigo)
do_shield:
        call sparkle
        ld a,1
        ld (shield_active),a
        ld hl,500           ; dura o dobro da raquete larga (250)
        ld (shield_timer),hl
        ld hl,$03C0         ; escudo: tom grave envolvente
        ld de,$0080
        call play_fx
        call draw_hud
        ret

; ovni apanhado: bonus fixo de pontos, sem duplicar por combo
do_ufo:
        call sparkle
        ld hl,$0090         ; ovni: bip muito agudo "espacial"
        ld de,$0030
        call play_fx
        ld b,UFO_PTS
        jp add_pts

; efeito sonoro:
; 128K -> blip AY sem parar o jogo (via sfx_t/music_step)
; 48K  -> click MUITO curto no beeper, para nao congelar o jogo
play_fx:
        ld a,(has_ay)
        or a
        jr nz,pf_ay
; --- caminho 48K: blip curto e nao-bloqueante-percetivel ---
; a rotina BEEPER da ROM: HL=periodo do tom, DE=duracao (nr de ciclos).
; limitamos a duracao a um valor pequeno para o som ser um "click"
; em vez de um "beeep" que congela ~meio frame.
        ld d,0
        ld e,8              ; duracao curtissima (~8 ciclos) = click rapido
        jp BEEPER
pf_ay:
; caminho AY (128K): guarda o periodo completo de 16 bits para o canal C.
; HL = periodo do tom (0-4095 uteis). Valores maiores = som mais grave.
        ld a,l
        ld (sfx_perl),a
        ld a,h
        and $0F             ; o AY so usa 12 bits de tom
        ld (sfx_perh),a
        ld a,8
        ld (sfx_t),a
        ret

; ---- nascimento (com velocidade por tipo) ----
try_spawn:
        ld a,(bolt_cnt)
        or a
        ret nz              ; Zeus ativo: so raios!
        ld a,(boss_type)
        cp 3
        ret z               ; Medusa ativa: so serpentes (lancadas por ela)
        ld a,(boss_type)
        cp 2
        ret z               ; Cronos ativo: estrelas so da ampulheta
        ld a,(spawn_cnt)
        dec a
        ld (spawn_cnt),a
        ret nz
        call rnd
        and 31
        add a,20
        ld (spawn_cnt),a
        ld ix,items
        ld b,NITEMS
ts_loop:
        ld a,(ix+0)
        or a
        jr z,ts_found
        ld de,ISIZE
        add ix,de
        djnz ts_loop
        ret
ts_found:
        ld a,(boss_type)
        cp 2
        jr nz,ts_pick       ; nao e o Cronos: sorteio normal
        ld a,T_STAR         ; Cronos: so estrelas!
        jr ts_set
ts_pick:
        call rnd
        and 15
        cp 14
        jr nc,ts_heart      ; 14 ou 15: coracao (dobro da frequencia anterior)
        cp 13
        jr z,ts_gold
        cp 12
        jr z,ts_wide
        cp 11
        jr z,ts_shield
        ld d,a
        ld a,(speed)
        ld b,a
        ld a,11
        sub b
        ld b,a
        ld a,d
        cp b
        jr nc,ts_bomb
        ld a,T_STAR
        jr ts_set
ts_heart:
        ld a,T_HEART
        jr ts_set
ts_gold:
        ld a,T_GOLD
        jr ts_set
ts_wide:
        ld a,T_WIDE
        jr ts_set
ts_shield:
        ld a,T_SHIELD
        jr ts_set
ts_bomb:
        ld a,T_BOMB
ts_set:
        ld (ix+0),a
        ld b,a
        ld a,(speed)
        ld c,a
        ld a,b
        cp T_BOMB           ; bombas: +2 (rapidas)
        jr nz,vs1
        ld a,c
        add a,2
        jr vs_set
vs1:    cp T_HEART          ; coracoes: -1 (lentos, min 1)
        jr nz,vs2
        ld a,c
        dec a
        jr nz,vs_set
        ld a,1
        jr vs_set
vs2:    cp T_GOLD           ; dourada: +1
        jr nz,vs3
        ld a,c
        inc a
        jr vs_set
vs3:    ld a,c              ; estrela: velocidade do nivel
vs_set:
        ld (ix+3),a
; coluna nova: desvio SIMETRICO de -7 a +7 (sinal e magnitude
; separados, para nao ter nenhuma tendencia media diferente de zero)
; NOTA: rnd() usa B como registo auxiliar interno e nao o restaura,
; por isso a magnitude tem de ficar em C entre as duas chamadas.
        call rnd
        and 7
        ld c,a              ; magnitude 0-7 (C: rnd() nao mexe neste)
        call rnd
        and 1
        jr z,tx_pos
        ld a,c
        neg
        ld c,a
tx_pos:
; reversao suave perto das bordas: um passeio aleatorio puro passa
; longos periodos "preso" perto de uma borda (lei do arco-seno); para
; a sensacao de jogo ficar mais equilibrada, se a posicao anterior ja
; estiver perto de um extremo, forca o desvio a apontar para o centro
        ld a,(last_x)
        cp 6
        jr nc,tx_chkhi
        ld a,c
        or a
        jp p,tx_apply       ; ja e positivo (para a direita): ok
        ld a,c
        neg
        ld c,a
        jr tx_apply
tx_chkhi:
        cp 26
        jr c,tx_apply
        ld a,c
        or a
        jp m,tx_apply       ; ja e negativo (para a esquerda): ok
        ld a,c
        neg
        ld c,a
tx_apply:
        ld a,(last_x)
        add a,c
        cp 200
        jr c,tx1
        xor a
        jr tx2
tx1:    cp 32
        jr c,tx2
        ld a,31
tx2:
; --- Regra 3: se a coluna coincide com meteoritos, afastar ---
        ld b,a              ; B = coluna candidata
        ld a,(rock_active)
        or a
        jr z,tx_ok          ; sem meteoritos: nada a evitar
        ld a,b
        call avoid_rocks    ; devolve em A uma coluna livre de meteoritos
        ld b,a
tx_ok:  ld a,b
        ld (ix+1),a
        ld (last_x),a
        ld (ix+2),Y_SPAWN
        ret

; recebe uma coluna em A; se cair na faixa dos meteoritos (rock base..+4),
; desvia-a para uma coluna segura. Devolve a coluna final em A.
avoid_rocks:
        ld c,a              ; C = coluna candidata
        ld a,(rock_data+1)  ; base dos meteoritos
        ld d,a              ; D = base
; se C esta em [base-1 .. base+5], mover para fora
        ld a,c
        sub d
        add a,1             ; C - base + 1
        cp 7
        jr nc,ar_safe       ; fora da faixa: seguro
; colide: escolher lado com mais espaco
        ld a,d
        cp 16
        jr nc,ar_left       ; meteoritos na metade direita -> por a estrela a esquerda
; meteoritos a esquerda -> estrela para a direita da faixa
        ld a,d
        add a,6             ; base+6 (a direita dos 3 blocos)
        cp 31
        jr c,ar_done
        ld a,31
        jr ar_done
ar_left:
        ld a,d
        sub 2               ; base-2 (a esquerda da faixa)
        jr nc,ar_done
        xor a
        jr ar_done
ar_safe:
        ld a,c
ar_done:
        ret

; ================= fim de jogo =================
game_over:
        call music_off
        call CLS
        ld a,2
        call CHAN_OPEN      ; forcar canal S: CLS pode deixar K/P activo
        ld hl,g_over
        call print_str
        ld hl,g_score
        call print_str
        ld hl,(score)
        call print_num5
        ld hl,g_combo
        call print_str
        ld a,(best_combo)
        call print_num2
        ld hl,melody2
        call play_tune      ; lamento de despedida
        call hs_check
        cp $FF
        jr z,go_tab
        push af
        ld hl,g_ini
        call print_str
        call enter_initials
        pop af
        call hs_insert
go_tab: ld hl,g_top
        call print_str
        call show_tab
        call pick_quote     ; citacao aleatoria de fim de jogo
        ld b,17             ; primeira linha da citacao
        call print_quote
        ld hl,g_key
        call print_str
        call wait_key
        call CLS
        ld a,2
        call CHAN_OPEN      ; forcar canal S: CLS pode deixar K/P activo
        jp title

; ---- tabela de recordes ----
; devolve em A a posicao (0-4) onde o score entra, ou $FF
hs_check:
        ld ix,hstab
        ld b,5
        ld c,0
hc_l:   ld hl,(score)
        ld e,(ix+3)
        ld d,(ix+4)
        or a
        sbc hl,de
        jr z,hc_nx          ; empate: nao desbanca esta posicao
        jr c,hc_nx          ; score menor: continua a procurar
        ld a,c
        ret
hc_nx:  inc c
        ld de,5
        add ix,de
        djnz hc_l
        ld a,$FF
        ret

; insere (init_buf)+score na posicao A, empurrando o resto
hs_insert:
        ld (hs_pos),a
        ld c,a
        ld a,4
        sub c
        jr z,hi_wr
        ld b,a
        ld a,0
hi_ml:  add a,5
        djnz hi_ml
        ld c,a
        ld b,0
        ld hl,hstab+19
        ld de,hstab+24
        lddr
hi_wr:  ld a,(hs_pos)
        ld b,a
        ld a,0
hi_ml2: add a,5
        djnz hi_ml2
        ld e,a
        ld d,0
        ld hl,hstab
        add hl,de
        ex de,hl
        ld hl,init_buf
        ld bc,3
        ldir
        ld hl,(score)
        ld a,l
        ld (de),a
        inc de
        ld a,h
        ld (de),a
        ret

; pede 3 letras (A-Z) e ecoa-as
enter_initials:
        ld hl,init_buf
        ld b,3
ei_l:   push bc
        push hl
        call read_letter
        pop hl
        ld (hl),a
        inc hl
        push hl
        rst 16
        pop hl
        pop bc
        djnz ei_l
        ret

; le uma letra do teclado (so A-Z)
read_letter:
rl_rel: xor a
        in a,($FE)
        cpl
        and 31
        jr nz,rl_rel
rl_s:   ld d,$FE
        ld e,8
        ld hl,keytab
rl_row: ld b,d
        ld c,$FE
        in a,(c)
        cpl
        and 31
        jr nz,rl_prs
        ld bc,5
        add hl,bc
        ld a,d
        rlca
        ld d,a
        dec e
        jr nz,rl_row
        jr rl_s
rl_prs: ld e,0
rl_bit: rra
        jr c,rl_hit
        inc e
        jr rl_bit
rl_hit: ld d,0
        add hl,de
        ld a,(hl)
        or a
        jr z,rl_s
        ret

; imprime as 5 entradas da tabela
show_tab:
        ld ix,hstab
        ld b,5
        ld d,11
        ld e,'1'
st_l:   push bc
        push de
        ld a,22
        rst 16
        pop de
        push de
        ld a,d
        rst 16
        ld a,10
        rst 16
        pop de
        push de
        ld a,e
        rst 16
        ld a,'.'
        rst 16
        ld a,' '
        rst 16
        ld a,(ix+0)
        rst 16
        ld a,(ix+1)
        rst 16
        ld a,(ix+2)
        rst 16
        ld a,' '
        rst 16
        ld l,(ix+3)
        ld h,(ix+4)
        call print_num5
        pop de
        inc d
        inc e
        ld bc,5
        add ix,bc
        pop bc
        djnz st_l
        ret

; ================= musica AY (128K) =================
; detecao: escreve e le de volta 2 registos
detect_ay:
        ld bc,$FFFD
        ld a,1
        out (c),a
        ld b,$BF
        ld a,$FF
        out (c),a
        ld b,$FF
        in a,(c)
        cp $0F              ; o AY mascara R1 a 4 bits
        ret nz
        ld bc,$FFFD
        xor a
        out (c),a
        ld b,$BF
        ld a,$5A
        out (c),a
        ld b,$FF
        in a,(c)
        cp $5A
        ret nz
        ld a,1
        ld (has_ay),a
        ld a,7              ; mixer: 3 tons, sem ruido
        ld d,$38
        call ay_write
        ret

ay_write:               ; A=registo, D=valor
        push bc
        ld bc,$FFFD
        out (c),a
        ld b,$BF
        out (c),d
        pop bc
        ret

music_off:
        ld a,(has_ay)
        or a
        ret z
        ld a,8
        ld d,0
        call ay_write
        ld a,9
        ld d,0
        call ay_write
        ld a,10
        ld d,0
        call ay_write
        ret

; um passo da musica (chamado a cada frame)
music_step:
        ld a,(has_ay)
        or a
        ret z
        ld a,(music_enabled)
        or a
        ret z
        ld a,(sfx_t)
        or a
        jr z,ms_mus
        dec a
        ld (sfx_t),a
        jr z,ms_off
        ld a,(sfx_perl)
        ld d,a
        ld a,4
        call ay_write
        ld a,(sfx_perh)
        ld d,a
        ld a,5
        call ay_write
        ld a,10
        ld d,13
        call ay_write
        jr ms_mus
ms_off: ld a,10
        ld d,0
        call ay_write
ms_mus: ld a,(mus_cnt)
        dec a
        ld (mus_cnt),a
        ret nz
        ld a,12             ; tempo: 12 frames por nota
        ld (mus_cnt),a
        ld a,(mus_pos)
        ld e,a
        inc a
        and 15
        ld (mus_pos),a
        ld hl,tune_a
        ld d,0
        add hl,de
        ld a,(hl)
        ld bc,$0800         ; b=reg volume, c=reg tom
        call play_note
        ld hl,tune_b
        ld d,0
        add hl,de
        ld a,(hl)
        ld bc,$0902
        call play_note
        ld a,(sfx_t)
        or a
        ret nz              ; canal C ocupado pelo efeito
        ld hl,tune_c
        ld d,0
        add hl,de
        ld a,(hl)
        ld bc,$0A04
        call play_note
        ret

; A=indice de nota (0=pausa), B=reg volume, C=reg tom fine
play_note:
        push de
        or a
        jr nz,pn_on
        ld a,b
        ld d,0
        call ay_write
        pop de
        ret
pn_on:  push bc
        add a,a
        ld hl,periods
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        inc hl
        ld d,(hl)
        ld e,a              ; E=fine, D=coarse
        pop bc
        ld a,c
        push de
        ld d,e
        call ay_write       ; tom fine
        pop de
        ld a,c
        inc a
        call ay_write       ; tom coarse (D ja tem)
        ld a,b
        ld d,10
        call ay_write       ; volume
        pop de
        ret

; ================= estrelas de fundo =================
NSTARS equ 14
NFAR   equ 7                ; primeiras 7 entradas: grupo "longe"

; calcula endereco de atributo: D=linha(0-23), E=coluna(0-31) -> HL
; (usa HL de 16 bits para o x32; a versao anterior fazia isto em A de
; 8 bits e transbordava silenciosamente para linhas >= 8!)
attr_addr:
        ld h,0
        ld l,d
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl           ; HL = linha*32 (ate 23*32=736, cabe em 16 bits)
        ld a,l
        add a,e
        ld l,a
        jr nc,aa_ok
        inc h
aa_ok:  ld a,h
        add a,$58
        ld h,a
        ret

; calcula endereco e mascara de bit para o pixel (E=x, B=y)
; devolve HL=endereco, A=mascara; usa B,C como auxiliares
calc_star:
        push bc
        ld a,e
        rrca
        rrca
        rrca
        and 31
        ld c,a
        call pix_addr
        pop bc
        ld a,e
        and 7
        ld b,a
        ld a,$80
        or a
        jr z,cs_done
cs_shr: rrca
        djnz cs_shr
cs_done:
        ret

; acende todas as estrelas e pinta as suas celulas (branco, sem bright)
init_stars:
        xor a
        ld (twinkle_idx),a
        ld (twinkle_idx2),a
        ld a,1
        ld (twinkle_cnt),a
        ld (twinkle_cnt2),a
        ld ix,star_tab
        ld b,NSTARS
is_loop:
        push bc
        ld e,(ix+0)
        ld a,(ix+1)
        ld b,a
        push bc
        call calc_star
        or (hl)
        ld (hl),a
        pop bc
; atributo da celula desta estrela: branco, sem bright
        ld a,b
        rrca
        rrca
        rrca
        and 31
        ld d,a              ; linha de caracteres
        ld a,e
        rrca
        rrca
        rrca
        and 31              ; coluna de caracteres
        ld e,a
        push de
        call attr_addr
        pop de
        ld a,7              ; branco, sem bright: fundo discreto
        ld (hl),a
        pop bc
        inc ix
        inc ix
        djnz is_loop
        ret

; alterna uma estrela do grupo "longe" (lento, periodo maior)
twinkle_far:
        ld a,(twinkle_cnt)
        dec a
        ld (twinkle_cnt),a
        ret nz
        ld a,9               ; lento: cintilar a cada 9 frames
        ld (twinkle_cnt),a
        ld a,(twinkle_idx)
        call tw_toggle
        ld a,(twinkle_idx)
        inc a
        cp NFAR
        jr nz,tf_store
        xor a
tf_store:
        ld (twinkle_idx),a
        ret

; alterna uma estrela do grupo "perto" (rapido, sensacao de proximidade)
twinkle_near:
        ld a,(twinkle_cnt2)
        dec a
        ld (twinkle_cnt2),a
        ret nz
        ld a,3               ; rapido: cintilar a cada 3 frames
        ld (twinkle_cnt2),a
        ld a,(twinkle_idx2)
        add a,NFAR
        call tw_toggle
        ld a,(twinkle_idx2)
        inc a
        cp NSTARS-NFAR
        jr nz,tn_store
        xor a
tn_store:
        ld (twinkle_idx2),a
        ret

; alterna a estrela de indice A (0-13) na tabela
tw_toggle:
        add a,a
        ld l,a
        ld h,0
        ld de,star_tab
        add hl,de
        ld e,(hl)
        inc hl
        ld a,(hl)
        ld b,a
        call calc_star
        xor (hl)
        ld (hl),a
        ret

; ================= estrela cadente =================
; risca diagonal rapida que atravessa o ceu de vez em quando
comet_step:
        ld a,(comet_life)
        or a
        jr nz,cm_move
; inativa: tenta lancar uma nova (probabilidade baixa)
        call rnd
        cp 3                 ; ~1.2% de hipotese por frame
        ret nc
        call rnd
        and 63
        ld (comet_x),a       ; nasce algures no 1/4 esquerdo-superior
        call rnd
        and 31
        add a,8
        ld (comet_y),a
        ld a,20
        ld (comet_life),a
        ret
cm_move:
; apagar posicao anterior (limpar so o bit certo, sem tocar no resto do byte)
        ld a,(comet_x)
        ld e,a
        ld a,(comet_y)
        ld b,a
        call calc_star       ; HL=endereco, A=mascara do bit
        cpl
        and (hl)
        ld (hl),a
; avancar (diagonal: +3 colunas, +2 linhas por frame)
        ld a,(comet_x)
        add a,3
        ld (comet_x),a
        cp 250
        jr nc,cm_end
        ld a,(comet_y)
        add a,2
        ld (comet_y),a
        cp 160
        jr nc,cm_end
; desenhar na nova posicao (branco brilhante)
        ld a,(comet_x)
        ld e,a
        ld a,(comet_y)
        ld b,a
        call calc_star
        or (hl)
        ld (hl),a
; atributo da celula: branco brilhante (cauda luminosa)
; NOTA: calc_star usa B como contador de deslocamento e devolve-o
; sempre a 0 -- por isso comet_y tem de ser relido da memoria aqui,
; nao pode confiar-se no B que sai da chamada anterior.
        ld a,(comet_y)
        rrca
        rrca
        rrca
        and 31
        ld d,a
        ld a,e
        rrca
        rrca
        rrca
        and 31
        ld e,a
        push de
        call attr_addr
        pop de
        ld a,$47             ; branco brilhante
        ld (hl),a
        ld a,(comet_life)
        dec a
        ld (comet_life),a
        ret
cm_end:
        xor a
        ld (comet_life),a
        ret

; ================= ovni bonus =================
; sobrevoa horizontalmente por 2 segundos, depois mergulha a direito
; como um item normal (apanhavel, vale UFO_PTS); so aparece com o
; jogo ja em curso (score>=100) e ricocheteia nas bordas do ecra.
UFO_Y     equ 16

ufo_step:
        ld a,(ufo_active)
        or a
        jr nz,uf_move
; inativo: tenta lancar um novo (raro), so depois de score>=100
        ld hl,(score)
        ld de,100
        or a
        sbc hl,de
        ret c
        call rnd
        cp 2                 ; ~0.8% de hipotese por frame
        ret nc
        ld a,1
        ld (ufo_active),a
        ld a,20
        ld (ufo_x),a
        ld a,3
        ld (ufo_dir),a
        ld a,100             ; ~2 segundos a sobrevoar
        ld (ufo_timer),a
        ret
uf_move:
; apagar posicao anterior
        ld a,(ufo_x)
        ld e,a
        ld a,UFO_Y
        ld b,a
        call calc_star
        cpl
        and (hl)
        ld (hl),a
; avancar; se sair da faixa 8..247, inverte a direcao (fica no lugar
; esta vez, retoma no proximo frame ja na nova direcao)
        ld a,(ufo_dir)
        ld d,a
        ld a,(ufo_x)
        ld c,a
        add a,d
        cp 8
        jr c,uf_bounce
        cp 248
        jr nc,uf_bounce
        ld c,a
        jr uf_have
uf_bounce:
        ld a,d
        neg
        ld (ufo_dir),a
uf_have:
        ld a,c
        ld (ufo_x),a
        ld e,a
        ld a,UFO_Y
        ld b,a
        call calc_star
        or (hl)
        ld (hl),a
; atributo: branco brilhante
        ld a,UFO_Y
        rrca
        rrca
        rrca
        and 31
        ld d,a
        ld a,e
        rrca
        rrca
        rrca
        and 31
        ld e,a
        push de
        call attr_addr
        pop de
        ld a,$47
        ld (hl),a
; contagem decrescente ate ao mergulho
        ld a,(ufo_timer)
        dec a
        ld (ufo_timer),a
        jr nz,uf_ret
; apagar o ovni em sobrevoo antes do mergulho
        ld a,(ufo_x)
        ld e,a
        ld a,UFO_Y
        ld b,a
        call calc_star
        cpl
        and (hl)
        ld (hl),a
        ld ix,items
        ld b,NITEMS
uf_find:
        ld a,(ix+0)
        or a
        jr z,uf_dive
        ld de,ISIZE
        add ix,de
        djnz uf_find
        ld a,10             ; sem ranhura livre: tenta de novo em breve
        ld (ufo_timer),a
        jr uf_ret
uf_dive:
        ld (ix+0),T_UFOF
        ld a,(ufo_x)
        rrca
        rrca
        rrca
        and 31
        ld (ix+1),a
        ld (ix+2),Y_SPAWN
        ld a,(speed)
        ld (ix+3),a
        xor a
        ld (ufo_active),a
uf_ret:
        ret

; ================= blocos de rocha (meteoritos) =================
; a partir dos 100 pontos, de vez em quando 3 blocos caem juntos,
; lado a lado, numa posicao aleatoria; funciona mesmo com Zeus ativo
; (sistema totalmente separado da tabela de itens partilhada).
; cada bloco: 3 bytes (vivo, coluna, linha-pixel)
ROCK_SPD  equ 4

rock_step:
        ld a,(rock_active)
        or a
        jp nz,rk_move
; inativo: tenta lancar uma vaga nova (rara)
        ld a,(boss_type)
        cp 2
        ret z                ; Cronos ativo: so estrelas, sem rochas novas
; numero de blocos conforme o nivel (speed): <=2 nenhum, 3-4 dois, >=5 tres
        ld a,(speed)
        cp 3
        ret c                ; nivel 1 (speed 2): sem meteoritos
        cp 5
        jr c,rk_two          ; niveis 2-3 (speed 3-4): 2 meteoritos
        ld a,3               ; nivel 4+ (speed 5+): 3 meteoritos
        jr rk_nset
rk_two: ld a,2
rk_nset:
        ld (rock_n),a
        call rnd
        cp 2                 ; ~0.8% de hipotese por frame
        ret nc
        call rnd
        and 31
        ld c,a
        ld a,26              ; margem para os blocos caberem
        cp c
        jr nc,rk_baseok
        ld c,a
rk_baseok:
; --- Regra 2: nao lancar meteoritos se houver objetos nas colunas deles ---
; os meteoritos ocupam c..c+4; verificar se algum item ativo esta em c-1..c+5
        ld ix,items
        ld b,NITEMS
rk_chk:
        ld a,(ix+0)
        or a
        jr z,rk_chknext     ; slot vazio
        ld a,(ix+1)         ; coluna do item
        sub c
        add a,1             ; deslocar: item_col - c + 1
        cp 7                ; dentro de [0..6] = faixa c-1..c+5?
        jr c,rk_abort       ; colide: abortar esta vaga
rk_chknext:
        ld de,ISIZE
        add ix,de
        djnz rk_chk
        jr rk_place
rk_abort:
        ret                 ; adiar: tenta noutra oportunidade
rk_place:
        ld a,c
        ld (rock_data+1),a
        add a,2
        ld (rock_data+4),a
        add a,2
        ld (rock_data+7),a
        ld a,24
        ld (rock_data+2),a
        ld (rock_data+5),a
        ld (rock_data+8),a
        ld a,1
        ld (rock_active),a
        ld (rock_data+0),a   ; bloco 1 sempre ativo
        ld a,(rock_n)
        cp 2
        jr c,rk_only1
        ld a,1
        ld (rock_data+3),a   ; bloco 2 ativo (>=2)
        ld a,(rock_n)
        cp 3
        jr c,rk_no3
        ld a,1
        ld (rock_data+6),a   ; bloco 3 ativo (==3)
        ret
rk_no3:
        xor a
        ld (rock_data+6),a
        ret
rk_only1:
        xor a
        ld (rock_data+3),a
        ld (rock_data+6),a
        ret
rk_move:
        ld hl,rock_data
        call rk_one
        ld hl,rock_data+3
        call rk_one
        ld hl,rock_data+6
        call rk_one
        ld a,(rock_data+0)
        ld b,a
        ld a,(rock_data+3)
        or b
        ld b,a
        ld a,(rock_data+6)
        or b
        or a
        ret nz
        xor a
        ld (rock_active),a
        ret

; processa um bloco: HL = endereco base (vivo,coluna,linha)
rk_one:
        ld a,(hl)
        or a
        ret z
        push hl
        inc hl
        ld a,(hl)
        ld c,a               ; coluna
        inc hl
        ld a,(hl)
        ld b,a               ; linha antiga
        call spr_clr         ; apaga o bloco na posicao antiga
        pop hl
        push hl
        inc hl
        inc hl
        ld a,(hl)
        add a,ROCK_SPD
        cp Y_CATCH
        jr nc,rk_arrived
        ld (hl),a            ; guarda nova linha
        ld b,a
        dec hl
        ld a,(hl)
        ld c,a               ; coluna
        ld de,spr_rock
        call spr_put
        ld e,7               ; branco, sem bright: aspeto de pedra/cimento
        call spr_attr
        pop hl
        ret
rk_arrived:
        pop hl
        push hl
        inc hl
        ld a,(hl)
        ld d,a               ; coluna do bloco
        ld a,(padx)
        ld c,a
        ld a,d
        cp c
        jr c,rk_miss
        ld a,(pwid)
        add a,c
        dec a
        cp d
        jr c,rk_miss
        pop hl
        ld (hl),0
        ld a,d
        ld (boom_x),a
        ld a,6              ; explosao amarela: bloco de rocha
        ld (boom_bd),a
        call do_hit
        ret
rk_miss:
        pop hl
        ld (hl),0
        ret

; ================= texto e som =================
print_str:
        ld a,(hl)
        cp $FF
        ret z
        push hl
        rst 16
        pop hl
        inc hl
        jr print_str

; imprime uma citacao centrada. HL -> dados da citacao:
; cada linha e' texto puro terminado por 0; a citacao termina com $FE.
; Uma linha que comece por $FD e' o autor (impresso em cyan em vez de amarelo).
; A primeira linha comeca em B (numero da linha do ecra).
print_quote:
        ld a,(hl)
        cp $FE
        ret z
; cor: amarelo por defeito; cyan se a linha comecar por $FD (autor)
        ld c,6              ; amarelo
        cp $FD
        jr nz,pq_col
        ld c,5              ; cyan (autor)
        inc hl              ; saltar o marcador $FD
pq_col:
        push hl
        push bc
        ld a,16             ; INK
        rst 16
        ld a,c
        rst 16
        pop bc
        pop hl
; contar o comprimento da linha (ate ao 0)
        push hl
        ld c,0
pq_len: ld a,(hl)
        or a
        jr z,pq_got
        inc hl
        inc c
        jr pq_len
pq_got:
        pop hl
; coluna = (32 - comprimento) / 2
        ld a,32
        sub c
        srl a
        ld d,a              ; d = coluna
        push hl
        push bc
        ld a,22
        rst 16
        ld a,b
        rst 16
        ld a,d
        rst 16
        pop bc
        pop hl
pq_pc:  ld a,(hl)
        or a
        jr z,pq_eol
        push hl
        push bc
        rst 16
        pop bc
        pop hl
        inc hl
        jr pq_pc
pq_eol:
        inc hl              ; saltar o 0 terminador
        inc b               ; proxima linha do ecra
        jr print_quote

; escolhe uma citacao aleatoria (0..NUM_QUOTES-1) e devolve o ponteiro em HL
pick_quote:
        call rnd
qp_mod: cp NUM_QUOTES
        jr c,qp_ok
        sub NUM_QUOTES
        jr qp_mod
qp_ok:  add a,a             ; indice * 2 (tabela de words)
        ld e,a
        ld d,0
        ld hl,quote_tab
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret

; imprime HL (0-65535) em 5 posicoes, espacos a esquerda
print_num5:
        xor a
        ld (pn5_go),a
        ld de,10000
        call pn5_dig
        ld de,1000
        call pn5_dig
        ld de,100
        call pn5_dig
        ld de,10
        call pn5_dig
        ld a,l
        add a,'0'
        rst 16
        ret

; subtrai DE de HL o maximo de vezes possivel (0-9); imprime o
; digito (ou espaco, se ainda nao apareceu nenhum digito relevante)
pn5_dig:
        ld b,'0'
pn5_loop:
        or a
        sbc hl,de
        jr c,pn5_back
        inc b
        jr pn5_loop
pn5_back:
        add hl,de
        ld a,(pn5_go)
        or a
        jr nz,pn5_show
        ld a,b
        cp '0'
        jr nz,pn5_mark
        ld a,' '
        rst 16
        ret
pn5_mark:
        ld a,1
        ld (pn5_go),a
pn5_show:
        ld a,b
        rst 16
        ret

; imprime A (0-99) em 2 digitos fixos, com zero a esquerda
print_num2:
        ld b,0
pn2_t:  cp 10
        jr c,pn2_done
        sub 10
        inc b
        jr pn2_t
pn2_done:
        push af
        ld a,b
        add a,'0'
        rst 16
        pop af
        add a,'0'
        rst 16
        ret

print_num3:
        ld c,0
pn_h:   cp 100
        jr c,pn_hd
        sub 100
        inc c
        jr pn_h
pn_hd:  ld b,0
pn_t:   cp 10
        jr c,pn_td
        sub 10
        inc b
        jr pn_t
pn_td:  push af
        push bc
        ld a,c
        or a
        jr nz,pn_c1
        ld a,' '
        rst 16
        jr pn_c2
pn_c1:  add a,'0'
        rst 16
pn_c2:  pop bc
        push bc
        ld a,c
        or a
        jr nz,pn_d1
        ld a,b
        or a
        jr nz,pn_d1
        ld a,' '
        rst 16
        jr pn_d2
pn_d1:  ld a,b
        add a,'0'
        rst 16
pn_d2:  pop bc
        pop af
        add a,'0'
        rst 16
        ret

; ---- paddle: pixel-perfect, pre-shifted sprites ----
; draw_paddle/erase_paddle: pmax garante sempre celula+largura<=31,
; por isso o desenho nunca precisa de recorte de bordo (mais simples e seguro)
draw_paddle:
        ld a,(padpx)
        and 7
        ld b,a              ; shift (0-7)
        ld a,(pwid)
        cp 3
        jr nz,dp_wt
        ld de,32
        ld hl,tab_norm
        jr dp_p
dp_wt:  ld de,48
        ld hl,tab_wide
dp_p:   ld a,b
        or a
        jr z,dp_p2
dp_m:   add hl,de
        dec a
        jr nz,dp_m
dp_p2:  push hl
        pop ix              ; IX = dados pre-deslocados para este shift
        ld a,(pwid)
        inc a
        ld e,a              ; bytes por linha (largura+1)
        ld a,(padpx)
        rrca
        rrca
        rrca
        and 31
        ld c,a              ; celula base (coluna byte)
        ld b,168
dr_r:   push bc
        call pix_addr       ; HL = endereco do primeiro byte desta linha
        ld b,e
dr_c:   ld a,(ix+0)
        ld (hl),a
        inc ix
        inc l               ; seguro: c+e<=32 sempre, nunca ultrapassa a linha
        djnz dr_c
        pop bc
        inc b
        ld a,b
        cp 176
        jr nz,dr_r
; atributos das celulas ocupadas pela raquete
; ($5AA0 = base da linha de atributos 21; c<=31 nunca transborda o byte baixo)
        ld hl,$5AA0
        ld d,0
        ld e,c
        add hl,de
        ld a,(padpx)
        and 7               ; desalinhamento: 0 = exatamente pwid celulas
        ld a,(pwid)
        jr z,da_wok
        inc a               ; desalinhada: ocupa uma celula extra
da_wok: ld b,a
        ld a,(shield_active)
        or a
        jr z,da_noshield
        ld a,(tick)
        and 8
        jr nz,da_blue
        jr da_cyan
da_noshield:
        ld a,(ctrl_swap)
        or a
        jr nz,da_swap       ; controlos trocados: cor de aviso
da_cyan:
        ld a,$45            ; cor normal: bright cyan
        jr da_go
da_blue:
        ld a,$41            ; escudo ativo: alterna para azul
        jr da_go
da_swap:
        ld a,(tick)
        and 8
        jr nz,da_swap2
        ld a,$43            ; controlos trocados: magenta a piscar
        jr da_go
da_swap2:
        ld a,$47            ; alterna para branco (chama a atencao)
da_go:
da_l:   ld (hl),a
        inc hl
        djnz da_l
        ret

erase_paddle:
        ld a,(padpx)
        rrca
        rrca
        rrca
        and 31
        ld c,a
        ld a,(pwid)
        inc a
        ld e,a
        ld b,168
pe_r:   push bc
        call pix_addr
        ld b,e
pe_c:   ld (hl),0
        inc l
        djnz pe_c
        pop bc
        inc b
        ld a,b
        cp 176
        jr nz,pe_r
; repor o atributo das celulas antigas (remove qualquer FLASH residual
; deixado pelo escudo, caso a raquete se tenha movido)
        ld hl,$5AA0
        ld d,0
        ld e,c
        add hl,de
        ld a,(pwid)
        inc a
        ld b,a
pe_a:   ld (hl),0
        inc hl
        djnz pe_a
        ret


rnd:
        ld a,r
        ld b,a
        ld a,(seed)
        add a,b
        rlca
        xor $B5
        ld (seed),a
        ret

; devolve em A o multiplicador de pontos (1-4) para o combo atual
combo_mult:
        ld a,(combo)
        cp 20
        jr nc,cm4
        cp 10
        jr nc,cm3
        cp 3
        jr nc,cm2
        ld a,1
        ret
cm2:    ld a,2
        ret
cm3:    ld a,3
        ret
cm4:    ld a,4
        ret

; som da estrela normal: um "bip" curto e limpo cujo tom SOBE conforme o
; multiplicador de combo cresce (x1 grave -> x4 agudo). Da feedback sonoro
; do combo sem precisar de olhar para o HUD.
catch_beep:
        call combo_mult     ; A = 1..4
        dec a               ; 0..3 (indice)
        add a,a             ; *2 (2 bytes por entrada)
        ld e,a
        ld d,0
        ld hl,catch_tone_tab
        add hl,de
        ld c,(hl)           ; low do periodo
        inc hl
        ld b,(hl)           ; high do periodo
        ld h,b
        ld l,c              ; HL = periodo para play_fx
        ld de,$0040
        call play_fx
        ret

; tabela de tons da apanha (periodo AY completo em HL): x1 -> x4
; periodos menores = som mais agudo
catch_tone_tab:
        defw $0200          ; x1 (grave)
        defw $01A0          ; x2
        defw $0140          ; x3
        defw $00F0          ; x4 (agudo)

draw_hud:
        ld a,22
        rst 16
        xor a
        rst 16
        xor a
        rst 16
        ld a,18              ; FLASH 0 (Zeus pode ter deixado ligado)
        rst 16
        xor a
        rst 16
        ld a,19              ; BRIGHT 0 (Zeus imprime com BRIGHT 1)
        rst 16
        xor a
        rst 16
        ld a,16
        rst 16
        ld a,7
        rst 16
        ld hl,msg_pontos
        call print_str
        ld hl,(score)
        call print_num5
        ld hl,msg_vidas
        call print_str
        ld a,16
        rst 16
        ld a,2
        rst 16
        ld a,(lives)
        or a
        jr z,no_hearts
        ld b,a
hloop:  push bc
        ld a,HEART
        rst 16
        pop bc
        djnz hloop
no_hearts:
        ld a,(lives)
        ld b,a
        ld a,5
        sub b
        jr z,hud_lvl
        ld b,a
sploop: push bc
        ld a,' '
        rst 16
        pop bc
        djnz sploop
hud_lvl:
        ld a,16
        rst 16
        ld a,7
        rst 16
        ld hl,msg_nivel
        call print_str
        ld a,(speed)
        dec a
        add a,'0'
        rst 16
        ld hl,msg_combo
        call print_str
        call combo_mult     ; devolve o multiplicador (1-4) em A
        push af
        cp 2                ; x2+ fica verde (destaque); x1 fica branco
        ld a,7
        jr c,cm_col
        ld a,4              ; verde
cm_col: push af
        ld a,16
        rst 16
        pop af
        rst 16
        ld a,'x'
        rst 16
        pop af
        add a,'0'
        rst 16
        ld a,16
        rst 16
        ld a,7
        rst 16
        ld hl,msg_wind
        call print_str
        ld a,(wind)
        cp 1
        jr z,hud_wr
        cp 2
        jr z,hud_wl
        ld a,' '
        rst 16
        ret
hud_wr: ld a,'>'
        rst 16
        ret
hud_wl: ld a,'<'
        rst 16
        ret

play_melody:
        ld hl,melody
play_tune:
pm1:    ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,b
        or c
        ret z
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld h,b
        ld l,c
        call BEEPER         ; melodias no beeper
        pop hl
        halt
        jr pm1

wait_key:
        halt
        xor a
        in a,($FE)
        cpl
        and 31
        jr nz,wait_key
wk2:    halt
        xor a
        in a,($FE)
        cpl
        and 31
        jr z,wk2
        ret

; espera uma tecla (o logo fica estatico, sem pulsar)
wait_key_anim:
wka_rel:
        halt
        call check_music_key
        xor a
        in a,($FE)
        cpl
        and 31
        jr nz,wka_rel
wka_prs:
        halt
        call check_music_key
        xor a
        in a,($FE)
        cpl
        and 31
        jr z,wka_prs
        ret

; tecla M: alterna a musica ligada/desligada (deteta so a transicao
; solto->premido, para nao alternar varias vezes com a tecla presa)
check_music_key:
        ld a,$7F
        in a,($FE)
        cpl
        and 4               ; bit2 = M
        ld c,a
        ld a,(m_key_prev)
        ld b,a
        ld a,c
        ld (m_key_prev),a
        or a
        ret z               ; M nao esta premida agora
        ld a,b
        or a
        ret nz              ; ja estava premida (sem transicao nova)
        ld a,(music_enabled)
        xor 1
        ld (music_enabled),a
        call music_off
        ld a,(music_enabled)
        or a
        ld hl,msg_music_on
        jr nz,cmk_show
        ld hl,msg_music_off
cmk_show:
        call print_str
        ret

; ================= dados =================
msg_pontos:
        defb 'SC:',$FF
msg_vidas:
        defb ' LI:',$FF
msg_nivel:
        defb ' LV:',$FF
msg_combo:
        defb ' CB:',$FF
msg_wind:
        defb ' W:',$FF
msg_zeus:
        defb 22,10,8,16,6,18,1,19,1,'ZEUS APPROACHES!',18,0,19,0,$FF
msg_zeus_clr:
        defb 22,10,8,16,0,'                ',$FF
msg_cronos:
        defb 22,10,6,16,5,18,1,19,1,'CRONOS SPEEDS TIME!',18,0,19,0,$FF
msg_cronos_clr:
        defb 22,10,6,16,0,'                   ',$FF
msg_medusa:
        defb 22,10,8,16,4,18,1,19,1,'MEDUSA STARES!',18,0,19,0,$FF
msg_medusa_clr:
        defb 22,10,8,16,0,'              ',$FF
mile_100:
        defb 22,11,10,16,6,19,1,'100 POINTS!',18,0,19,0,$FF
mile_500:
        defb 22,11,10,16,6,19,1,'500 POINTS!',18,0,19,0,$FF
mile_1000:
        defb 22,11,10,16,6,19,1,'1000 POINTS!',18,0,19,0,$FF
mile_1500:
        defb 22,11,3,16,6,19,1,'To infinity... and beyond!',18,0,19,0,$FF
banner_clear:
        defb 22,11,3,16,0,'                          ',$FF
pm_paused:
        defb 22,9,2,16,6,19,1,'PAUSED',18,0,19,0,$FF
pm_continue:
        defb 22,10,4,16,7,'CONTINUE',$FF
pm_restart:
        defb 22,11,4,16,7,'RESTART',$FF
pm_title:
        defb 22,12,4,16,7,'TITLE',$FF
g_over:
        defb 22,3,11,16,2,19,1,18,1,'GAME OVER!',18,0,$FF
g_score:
        defb 22,5,9,16,7,19,0,'SCORE: ',$FF
g_combo:
        defb 22,6,7,16,5,'BEST COMBO: ',$FF
g_ini:
        defb 22,7,4,16,6,18,1,19,1,'HIGH SCORE! INITIALS: ',18,0,19,0,$FF
g_top:
        defb 22,9,10,16,7,'-- TOP 5 --',$FF
g_key:
        defb 22,21,8,16,7,18,1,'PRESS ANY KEY',18,0,$FF

NUM_QUOTES equ 15
quote_tab:
        defw quo_0,quo_1,quo_2,quo_3,quo_4
        defw quo_5,quo_6,quo_7,quo_8,quo_9
        defw quo_10,quo_11,quo_12,quo_13,quo_14

quo_0:  defb 'Somewhere, something incredible',0
        defb 'is waiting to be known',0
        defb $FD,'- Carl Sagan',0,$FE
quo_1:  defb 'The cosmos is within us',0
        defb $FD,'- Carl Sagan',0,$FE
quo_2:  defb 'The universe is under no',0
        defb 'obligation to make sense to you',0
        defb $FD,'- Neil deGrasse Tyson',0,$FE
quo_3:  defb 'Look up at the stars',0
        defb 'and not down at your feet',0
        defb $FD,'- Stephen Hawking',0,$FE
quo_4:  defb 'The only way to discover the',0
        defb 'limits of the possible is to',0
        defb 'venture a little past them',0
        defb $FD,'- Arthur C. Clarke',0,$FE
quo_5:  defb 'Any sufficiently advanced',0
        defb 'technology is',0
        defb 'indistinguishable from magic',0
        defb $FD,'- Arthur C. Clarke',0,$FE
quo_6:  defb 'Truth is ever to be',0
        defb 'found in simplicity',0
        defb $FD,'- Isaac Newton',0,$FE
quo_7:  defb 'Per aspera ad astra',0
        defb '(Through hardships to the stars)',0
        defb $FD,'- Seneca',0,$FE
quo_8:  defb 'Live long and prosper',0
        defb $FD,'- Spock',0,$FE
quo_9:  defb 'Insufficient facts',0
        defb 'always invite danger',0
        defb $FD,'- Spock',0,$FE
quo_10: defb 'Risk is our business',0
        defb $FD,'- Captain Kirk',0,$FE
quo_11: defb 'Do. Or do not.',0
        defb 'There is no try.',0
        defb $FD,'- Yoda',0,$FE
quo_12: defb 'Mankind was born on Earth.',0
        defb 'It was never meant to die here',0
        defb $FD,'- Interstellar',0,$FE
quo_13: defb 'In space no one',0
        defb 'can hear you scream',0
        defb $FD,'- Alien',0,$FE
quo_14: defb 'We are star-stuff',0
        defb $FD,'- Carl Sagan',0,$FE

t_titulo:
        defb 22,2,13,16,6,19,1,'ICARUS',$FF
t_info1:
        defb 22,6,4,19,0,16,7,'STAR = LEVEL POINTS   ',16,6,19,1,STAR1,$FF
t_info2:
        defb 22,7,4,19,0,16,7,'GOLD STAR = 5 POINTS  ',16,6,19,1,GOLD_C,$FF
t_info3:
        defb 22,8,4,19,0,16,7,'AVOID THE ARROWS      ',16,2,19,1,BOMB,$FF
t_info4:
        defb 22,9,4,19,0,16,7,'HEART = EXTRA LIFE    ',16,3,19,1,HEART,$FF
t_boss:
        defb 22,10,4,19,0,16,7,'BEWARE OF ZEUS!      ',16,5,19,1,BOLT_C,BOLT_C,BOLT_C,$FF
t_keys:
        defb 22,12,2,19,0,16,5,'O/P OR KEMPSTON TO MOVE',$FF
t_pause:
        defb 22,13,9,16,5,'SPACE = PAUSE',$FF
t_rec:
        defb 22,15,9,16,7,'BEST: ',$FF
t_press:
        defb 22,20,8,16,7,18,1,'PRESS ANY KEY',18,0,$FF
msg_music_on:
        defb 22,19,10,16,5,'M = MUSIC ON ',$FF
msg_music_off:
        defb 22,19,10,16,5,'M = MUSIC OFF',$FF
t_credits:
        defb 22,16,2,16,7,19,0,'A GAME BY MMM WITH CLAUDE AI',$FF
t_legend1:
        defb 22,17,7,16,5,'SC=SCORE  LI=LIVES',$FF
t_legend2:
        defb 22,18,7,16,5,'LV=LEVEL  CB=COMBO',$FF

melody:
        defw 1642,39
        defw 1297,49
        defw 1086,59
        defw 806,78
        defw 1086,45
        defw 806,150
        defw 0

zeus_speed_tab: defb 7,7,3,3,1,1

melody_100:
        defw 1046,30
        defw 1318,40
        defw 0
melody_500:
        defw 1046,25
        defw 1318,25
        defw 1568,45
        defw 0
melody_1000:
        defw 1046,20
        defw 1318,20
        defw 1568,20
        defw 2093,60
        defw 0

; lamento de game over
melody2:
        defw 1642,45
        defw 1958,50
        defw 2202,55
        defw 2624,60
        defw 3314,140
        defw 0

score:  defw 0
score10: defb 0
next_boss: defw 200
lives:  defb 0
padx:   defb 0
seed:   defb 123
tick:   defb 0
speed:  defb 0
spawn_cnt: defb 0
gover:  defb 0
kemp:   defb 0
gold_at: defb $46
boom_x: defb 0
wind:   defb 0
wind_cnt: defb 100
bolt_cnt: defb 0
boss_type: defb 0        ; 0=nenhum, 1=Zeus, 2=Cronos, 3=Medusa
boss_pending: defb 0     ; 1 = boss marcado, a aguardar ecra limpo
boss_timer: defw 0       ; tempo de vida do boss atual (frames ou contagem)
boss_rotation: defb 0    ; qual boss vem a seguir (0=Zeus,1=Cronos,2=Medusa)
cronos_spd_sv: defb 0    ; velocidade guardada durante o Cronos
hour_x: defb 1           ; coluna atual da ampulheta (Cronos)
hour_dir: defb 1         ; direcao do vaivem (1=direita, 0=esquerda)
hour_spawn: defb 0       ; contador para largar estrelas
hour_count: defb 0       ; quantas estrelas ja foram largadas (0..5)
boss_frm: defb 0
zeus_x: defb 2
medusa_x: defb 2         ; coluna da Medusa
snake_cnt: defb 0        ; serpentes que faltam lancar
boom_bd: defb 2
last_x: defb 14
comet_x: defb 0
comet_y: defb 0
comet_life: defb 0
twinkle_idx: defb 0
twinkle_cnt: defb 0
twinkle_idx2: defb 0
twinkle_cnt2: defb 0
best_combo: defb 0
shield_active: defb 0
shield_timer: defw 0
ctrl_swap: defb 0        ; 1 = comandos trocados (efeito da serpente)
swap_timer: defw 0       ; frames restantes de comandos trocados
hit_active: defb 0
hit_phase: defb 0
hit_subcnt: defb 0
hit_x: defb 0
ufo_active: defb 0
ufo_x: defb 0
ufo_dir: defb 0
ufo_timer: defb 0
rock_active: defb 0
rock_n: defb 0
rock_data: defb 0,0,0, 0,0,0, 0,0,0
banner_timer: defb 0
mile_ptr: defw 0
pulse_cnt: defb 0
music_enabled: defb 1
m_key_prev: defb 0
pause_sel: defb 0
pm_prev: defb 0
cur_border: defb 1
border_tab: defb 1,5,4,6,2,3,7   ; nivel 1..7: azul,ciano,verde,amarelo,vermelho,magenta,branco
pwid:   defb 3
pmax:   defb 29
wide_t: defb 0
combo:  defb 0
boss_lv: defb 0
zeus_count: defb 0
hs_beaten: defb 0
sfx_t:  defb 0
sfx_perl: defb 1
sfx_perh: defb 0
padpx:  defb 112

; sprites pre-deslocados da raquete (calculados previamente em Python)
; 8 deslocamentos x 8 linhas; tab_norm=4 bytes/linha, tab_wide=6
        include "tabs.inc"
anim_ptr: defw spr_star1
has_ay: defb 0
mus_pos: defb 0
mus_cnt: defb 1
hs_pos: defb 0
init_buf: defb 'A','A','A'

; tabela de recordes: 3 iniciais + pontuacao de 16 bits, 5 entradas
hstab:  defb 'Z','X','S'
        defw 50
        defb 'C','L','A'
        defw 40
        defb 'U','D','E'
        defw 30
        defb 'B','A','S'
        defw 20
        defb 'I','C','O'
        defw 10
pn5_go: defb 0

; mapa de teclado (5 teclas por linha de porta)
keytab: defb 0,'Z','X','C','V'
        defb 'A','S','D','F','G'
        defb 'Q','W','E','R','T'
        defb 0,0,0,0,0
        defb 0,0,0,0,0
        defb 'P','O','I','U','Y'
        defb 0,'L','K','J','H'
        defb 0,0,'M','N','B'

; periodos AY (clock 1.7734 MHz)
periods:
        defw 0
        defw 847            ; C3
        defw 755            ; D3
        defw 672            ; E3
        defw 635            ; F3
        defw 565            ; G3
        defw 504            ; A3
        defw 449            ; B3
        defw 423            ; C4
        defw 377            ; D4
        defw 336            ; E4
        defw 317            ; F4
        defw 283            ; G4
        defw 252            ; A4
        defw 224            ; B4
        defw 212            ; C5

; melodia em loop de 16 passos (3 canais)
tune_a: defb 8,10,12,10, 11,13,15,13, 12,10,8,10, 9,11,9,7
tune_b: defb 1,0,5,0, 4,0,1,0, 5,0,3,0, 2,0,5,0
tune_c: defb 5,8,10,8, 6,9,11,9, 8,10,12,10, 6,9,7,7

; posicoes das estrelas de fundo (x 0-255, y 16-152)
logo_pat:
        defb %1111,%0110,%0110,%0110,%1111      ; I
        defb %0111,%1000,%1000,%1000,%0111      ; C
        defb %0110,%1001,%1111,%1001,%1001      ; A
        defb %1110,%1001,%1110,%1010,%1001      ; R
        defb %1001,%1001,%1001,%1001,%0110      ; U
        defb %0111,%1000,%0110,%0001,%1110      ; S

star_tab:
; grupo LONGE (indices 0-6): y pequeno, cintilar lento
        defb 12,24,  230,20,  60,44,  180,52
        defb 130,28, 20,40,   200,36
; grupo PERTO (indices 7-13): y maior, cintilar rapido
        defb 20,76,  200,68,  100,96, 240,110
        defb 8,120,  150,132, 220,140

; tabela: (tipo, coluna, linha, velocidade) x 3
items:  defb 0,0,0,0
        defb 0,0,0,0
        defb 0,0,0,0

; ================= graficos =================
udg_data:
spr_padl:
        defb $3F,$7F,$FF,$FF,$FF,$7F,$3F,$00
spr_padm:
        defb $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
spr_padr:
        defb $FC,$FE,$FF,$FF,$FF,$FE,$FC,$00
spr_star1:
        defb $10,$38,$FE,$7C,$38,$6C,$C6,$00
spr_heart:
        defb $66,$FF,$FF,$FF,$7E,$3C,$18,$00
spr_star2:
        defb $00,$10,$38,$7C,$38,$10,$00,$00
spr_bomb:
        defb $42,$66,$3C,$18,$18,$7E,$3C,$18
spr_gold:
        defb $10,$54,$38,$EE,$38,$54,$10,$00
spr_boom1:
        defb $92,$44,$28,$D6,$28,$44,$92,$00
spr_boom2:
        defb $00,$28,$54,$28,$54,$28,$00,$00
spr_bolt:
        defb $0C,$18,$30,$3E,$0C,$18,$30,$00
spr_ztl:
        defb $00,$01,$03,$07,$0F,$0F,$0F,$07
spr_ztm:
        defb $AA,$FE,$FF,$99,$FF,$C3,$FF,$FF
spr_ztr:
        defb $00,$80,$C0,$E0,$F0,$F0,$F0,$E0
spr_zbl:
        defb $03,$01,$00,$00,$00,$00,$00,$00
spr_zbm:
        defb $FF,$FF,$7E,$7E,$3C,$3C,$18,$00
spr_zbr:
        defb $C0,$80,$00,$00,$00,$00,$00,$00
spr_block:
        defb $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
spr_wide:
        defb $00,$24,$66,$FF,$FF,$66,$24,$00
spr_bubble:
        defb $3C,$42,$99,$A5,$99,$81,$42,$3C
spr_rock:
        defb $DB,$B6,$DB,$6D,$DB,$B6,$DB,$6D
spr_hour_tl:
        defb $FF,$FF,$7F,$3F,$1F,$0F,$07,$03
spr_hour_tr:
        defb $FF,$FF,$FE,$FC,$F8,$F0,$E0,$C0
spr_hour_bl:
        defb $03,$06,$0C,$18,$31,$63,$FF,$FF
spr_hour_br:
        defb $C0,$60,$30,$18,$8C,$C6,$FF,$FF
spr_snake:
        defb $60,$F0,$B0,$60,$30,$18,$30,$60
spr_med_tl: defb $44,$AA,$44,$2A,$3F,$40,$5C,$5C
spr_med_tm: defb $44,$AA,$44,$AA,$FF,$02,$3A,$3A
spr_med_tr: defb $40,$A0,$40,$80,$00,$00,$00,$00
spr_med_bl: defb $40,$47,$20,$20,$10,$08,$07,$03
spr_med_bm: defb $02,$E2,$04,$04,$08,$10,$E0,$C0
spr_med_br: defb $00,$00,$00,$00,$00,$00,$00,$00

        end start

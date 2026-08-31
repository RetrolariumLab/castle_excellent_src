; NES CPU-visible hardware registers used by Castle Excellent

PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
OAM_ADDR = $2003
OAM_DATA = $2004
PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_DATA = $2007

APU_PL1_VOL = $4000
APU_PL1_SWEEP = $4001
APU_PL1_LO = $4002
APU_PL1_HI = $4003
APU_PL2_VOL = $4004
APU_PL2_SWEEP = $4005
APU_PL2_LO = $4006
APU_PL2_HI = $4007
APU_TRI_LINEAR = $4008
APU_TRI_LO = $400A
APU_TRI_HI = $400B
APU_NOISE_VOL = $400C
APU_NOISE_LO = $400E
APU_NOISE_HI = $400F
OAM_DMA = $4014
APU_STATUS = $4015
JOYPAD1 = $4016
JOYPAD2 = $4017
APU_FRAME = $4017

ControllerSerialBitCount = 8
ControllerButtonA = $01
ControllerButtonB = $02
ControllerButtonSelect = $04
ControllerButtonStart = $08
ControllerButtonUp = $10
ControllerButtonDown = $20
ControllerButtonLeft = $40
ControllerButtonRight = $80
CastleMapExitButtons = ControllerButtonA | ControllerButtonB | ControllerButtonSelect

PpuCtrlGameplayNoNmi = $30
PpuCtrlGameplayNmi = $B0
PpuCtrlCastleMapNmi = $B8
PpuMaskRenderingDisabled = $00
PpuMaskGameplay = $1E
ChrBankCount = 4
PowerOnSignatureCheckedBytes = 3
NmiFramesPerMainUpdate = 2
OamDmaBufferPage = $02

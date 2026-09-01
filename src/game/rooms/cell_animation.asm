; Room-cell animation scans and frame tables
; CPU range $A3D2-$A496
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

AnimateRoomCells:
    JSR AnimateFastRoomCells
    LDA RoomFrameCounter
    LSR A
    BCC ReturnRoomCellAnimation
    INC RoomCellAnimationCounter
    BMI ReturnRoomCellAnimation
    LDA RoomCellAnimationCounter
    AND #RoomCellSlowAnimationDividerMask
    BNE ReturnRoomCellAnimation
    LDA #>RoomCells
    STA AnimatedRoomCellPointerHi
    LDA #<RoomCells
    STA AnimatedRoomCellPointerLo

ScanSlowAnimatedRoomCells:
    LDY #$00
    LDA (AnimatedRoomCellPointerLo),Y
    CMP #SlowAnimatedCellFirst
    BCC AdvanceSlowRoomCellScan
    CMP #SlowAnimatedCellEnd
    BCS AdvanceSlowRoomCellScan
    TAX
    LDA SlowRoomCellAnimationFrames - SlowAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate

AdvanceSlowRoomCellScan:
    INC AnimatedRoomCellPointerLo
    BNE CheckSlowRoomCellScanEnd
    INC AnimatedRoomCellPointerHi

CheckSlowRoomCellScanEnd:
    LDA AnimatedRoomCellPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA AnimatedRoomCellPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanSlowAnimatedRoomCells

ReturnRoomCellAnimation:
    RTS

SlowRoomCellAnimationFrames:
    .byte $46, $47, $48, $45

AnimateFastRoomCells:
    LDA RoomFrameCounter
    LSR A
    BCC ReturnFastRoomCellAnimation
    LDA #>RoomCells
    STA AnimatedRoomCellPointerHi
    LDA #<RoomCells
    STA AnimatedRoomCellPointerLo

ScanFastAnimatedRoomCells:
    LDY #$00
    LDA (AnimatedRoomCellPointerLo),Y
    CMP #DecrementingAnimatedCellFirst
    BCC CheckIncrementingAnimationRange
    CMP #DecrementingAnimatedCellEnd
    BCS CheckIncrementingAnimationRange
    TAX
    LDA DecrementingRoomCellAnimationFrames - DecrementingAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    CPX #DecrementingAnimatedCellRedrawEnd
    BCS AdvanceFastRoomCellScan
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    JMP AdvanceFastRoomCellScan

CheckIncrementingAnimationRange:
    CMP #IncrementingAnimatedCellFirst
    BCC AdvanceFastRoomCellScan
    CMP #IncrementingAnimatedCellEnd
    BCS AdvanceFastRoomCellScan
    TAX
    LDA IncrementingRoomCellAnimationFrames - IncrementingAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    CPX #IncrementingAnimatedCellRedrawEnd
    BCS AdvanceFastRoomCellScan
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate

AdvanceFastRoomCellScan:
    INC AnimatedRoomCellPointerLo
    BNE CheckFastRoomCellScanEnd
    INC AnimatedRoomCellPointerHi

CheckFastRoomCellScanEnd:
    LDA AnimatedRoomCellPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA AnimatedRoomCellPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanFastAnimatedRoomCells

ReturnFastRoomCellAnimation:
    RTS

DecrementingRoomCellAnimationFrames:
    .byte $38, $35, $36, $37, $3C, $39, $3A, $3B, $40, $3D, $3E, $3F

IncrementingRoomCellAnimationFrames:
    .byte $57, $58, $59, $56, $5B, $5C, $5D, $5A, $5F, $60, $61, $5E

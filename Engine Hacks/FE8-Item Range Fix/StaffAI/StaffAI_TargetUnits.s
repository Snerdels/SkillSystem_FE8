.thumb

.include "_ItemAIDefinitions.s"

.equ MovGetter, OffsetList + 0x0
.equ StaffRangeGetter, OffsetList + 0x4
.equ AIStaffRangeBuilder, OffsetList + 0x8
@parameters: 	r0= item slot, r1= targeting condition

push	{r4-r7,lr}	
mov 	r5, r8  	
mov 	r6, r9  	
mov 	r7, r10 	
push	{r5-r7} 			@start by pushing everything from r4 to r10
add 	sp, #-0x28			@create stack pocket
str 	r0,[sp,#0x10]		@store item slot number in stack pocket
mov 	r9,r1				@mov pointer to targeting condtion check to r9
mov 	r0, #0x0	
mov 	r10, r0 	
mov 	r1, #0x1
neg 	r1, r1
str 	r1, [sp, #0x14]		@zero out sections in stack pocket
str 	r1, [sp, #0x18]
str 	r1, [sp, #0x1C]
str 	r1, [sp, #0x20]

ldr 	r7, =ActiveUnit
ldr 	r0, [r7]
_bldr 	r3, MovBuild
@mov 	r14, r3
@.short	0xF800 
ldr 	r0, [sp, #0x18]
_bldr 	r3, MagicSealCheck

ldr 	r0, =turnList
add 	r0, #0x7B
ldrb	r1, [r0]
mov 	r0, #0x4
and 	r0, r1
cmp 	r0, #0x0
bne 	End

@get item range
ldr 	r0, [r7]	@get char pointer
ldr 	r1, [sp, #0x10] @get item slot
lsl 	r1, r1, #0x1	
add 	r1, #0x1E	@get item id
ldrh	r1, [r0,r1]
ldr 	r3, StaffRangeGetter
_blr 	r3

str 	r0, [sp, #0x24] 	@hold on to staff range here

mov 	r4, #0x1
mov 	r8, r4
loopstart:
mov 	r0, r8
_bldr 	r3, RamUnitByID
mov 	r6, r0
cmp 	r6, #0x0
beq 	reloop
ldr 	r0, [r6]
cmp 	r0, #0x0
beq 	reloop

@make sure unit is alive and on the map
ldr 	r0, [r6, #0xC]	
ldr 	r1, =#0x10005
and 	r0, r1
cmp 	r0, #0x0
bne reloop

ldr 	r0, [r7]
ldr 	r3, MovGetter
_blr	r3
@.short 0xF800	@get move of unit

add 	r1, sp, #0x24	@get pointer to staff range
ldrh 	r1, [r1]	@get max range
add 	r0, r0, r1
str 	r0, [sp]	@hold on to mov + max range

ldr 	r2, [r7]
mov 	r0, #0x10		@get coordinates of active unit
ldsb 	r0, [r2, r0]
mov 	r1, #0x11
ldsb	r1, [r2, r1]
ldrb 	r2, [r6, #0x10]	@get coordinates of target unit
ldrb 	r3, [r6, #0x11]
_bldr 	r4, IsTileReachable
cmp r0, #0x0
beq reloop

mov 	r0, sp
ldr 	r1, [r7]
mov 	r2, r6
_blr 	r9
cmp 	r0, #0x0	@returns 1 if targeting condition is met, otherwise return 0
beq 	reloop

@fill in rangemap based on staff range and target tile
ldrb 	r0, [r6, #0x10]	@get coordinates of target unit
ldrb 	r1, [r6, #0x11]
add 	r2, sp, #0x24	@get pointer to staff range
bl RangeBuilder
@ldr 	r2, [sp, #0x24]
@ldr 	r3, AIStaffRangeBuilder
@bl		Jump

add 	r0, sp, #0xC
_bldr 	r3, FindNewSpot
cmp 	r0, #0x0
beq reloop

ldrb	r0,[r6,#0xB]
mov 	r10, r0
bl		PocketWrite

reloop:
mov 	r0, #0x1
add 	r8, r0
mov 	r1, r8
cmp 	r1, #0xBF
bgt 	loopexit
b		loopstart

loopexit:
mov 	r3, r10
cmp 	r3, #0x0
beq 	End 		@don't write to AAS if no target was found

ldr 	r0, [sp, #0x14]
ldr 	r1, [sp, #0x18]
ldr 	r3, [sp, #0x1C]
ldr 	r2, [sp, #0x10]
str 	r2, [sp]
mov 	r2, #0x0
str 	r2, [sp, #0x4]
str 	r2, [sp, #0x8]
mov 	r2, #0x5
_bldr r4, ActionWrite
@ldr 	r4, ActionWrite
@mov 	r14, r4
@.short	0xF800		@write targeting info to AAS

End:
add 	sp, #0x28
pop 	{r3-r5}
mov 	r8, r3
mov 	r9, r4
mov 	r10, r5
pop 	{r4-r7}
pop 	{r3}
Jump:
bx	r3

PocketWrite:
@write target info to stack pocket
	add 	r0, sp, #0xC
	mov 	r2, #0x0
	ldsh 	r1, [r0, r2]
	str 	r1, [sp, #0x14]
	mov 	r2, #0x2
	ldsh 	r1, [r0, r2]
	str 	r1, [sp, #0x18]
	ldrb 	r1, [r6, #0x0B]
	str 	r1, [sp, #0x1C]
	bx 	lr
	
RangeBuilder:
push {r4-r6,lr}
mov 	r4, r0
mov 	r5, r1
mov 	r6, r2
@clear out range map
ldr 	r0, =RangeMap
ldr 	r0, [r0]
mov 	r1, #0x0
_bldr 	r3, FillMap
@mov 	lr, r3
@.short 0xF800

@build max range
mov 	r0, r4
mov 	r1, r5
ldrh 	r2, [r6]
ldr 	r3, =#AddRange
mov 	lr, r3
mov 	r3, #0x1
.short 0xF800

@clear out everything below min range
ldrh 	r2, [r6, #0x2]
cmp 	r2, #0x0
ble SkipMinRange
sub 	r2, #0x1
mov 	r0, r4
mov 	r1, r5
ldr 	r3, =#AddRange
mov 	lr, r3
mov 	r3, #0x1
neg 	r3, r3
.short 0xF800
SkipMinRange:
pop 	{r4-r6}
pop {r15}

.ltorg
.align
OffsetList:

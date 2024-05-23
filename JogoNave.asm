#   unit width in pixels   :  8

#   unit height in pixels  :  8 

#   display width in pixels:  256

#   display height in pixels: 256




	.data

frameBuffer:

        .space 0x80000

msgVitoria:   .asciiz "Você venceu!!!"
msgDerrota:   .asciiz "Você perdeu!!!"

    # Main body

    	

	.text

main:
	li $s0, 1920 		#Registro usado para localizar a posição da nave amiga
	li $t0, 0x000fff00 	#Amigo cor verde
	jal DesenhaAmigo
	
	li $s1, 2172 		#Registro usado para localizar a posição da nave inimiga
	li $t0, 0x00ff1300	#inimigo cor vermelha
	jal DesenhaInimigo	
	
	li $v0, 30	#Pegar o tempo do sistema para controlr a velocidade e movimento do jogo
    	syscall
    	
    	move $s4, $a0	#referencia para movimentaao de tiro
    	move $s5, $a0	#referencia para movimentacao do inimigo
	

key_wait:

    	li $v0, 30	#Pega o tempo atual no sistema
    	syscall
    	
    	sub $t4, $a0, $s4
    	sub $t5, $a0, $s5
    	
    	
    	bge $t4, 100, MoveTiros		#a cada 0.1 segundo os tiros se movimentam 1 bit
    	bge $t5, 500, MoveInimigo	#o inimigo se move a cada 0.5 segundos
    	
    	
    	la $t1,frameBuffer		#
	move $t2, $s0 			#
	addu $t1,$t1,$t2 		# Avalia caso de derrota
	addi $t1, $t1, 132		#
	beq $t1, $s3, FinalDerrota	#
	
	
	la $t1,frameBuffer     		# 
	move $t2, $s1         		#
	addu $t1,$t1,$t2		#Avalia caso de Vitoria
	subi $t1, $t1, 4		#
	beq $t1, $s2, FinalVitoria	#
    	
    	
  	li $v0, 1000
	li $a0, 1
	

wait:

	sub $v0,$v0,$a0
	bne $zero,$v0,wait

	li $v0, 30
	syscall

	lw      $t0, 0xffff0000

	andi    $t0, $t0, 0x00000001  

	beqz    $t0, key_wait

    
	lbu     $a0, 0xffff0004

	

	move    $s7, $a0  	# Save Key
	
	
	
	li      $t1,'a'
	beq     $a0, $t1, DesenhaAmigoCima
	li      $t1,'z'
	beq     $a0, $t1, DesenhaAmigoBaixo
	li      $t1,' '
	beq     $a0, $t1, GeraTiroAmigo
	j	key_wait

MoveTiros:
	li $v0, 30				#Atualiza o tempo do registro
    	syscall					#
    	move $s4, $a0				#
    	jal MoveTiroAmigo			#
    	beq $t9, $zero, CriaTiroInimigo		#Cria tiro inimigo se não existir
    	bne $t9, $zero, MoveTiroInimigo		#Move tiro inimigo se não existir
    	

MoveTiroInimigo:				
	addi $t9, $t9, 4			#Contador para saver onde o tiro está na tela
	bge $t9, 108, AcabaTiroInimigo		#Se o tiro chegou ao fim da tela a função apaga o tiro
	
	li $t1, 0x004dff00
	
	subi $s3, $s3, 4
	
	move $t0, $s3 
	sw $t1,($t0)		
	
	addi $t0, $t0, 4
	sw $zero,($t0)				#A funcao como um todo apenas movimenta os bits para a esquerda
	
	addi $t0, $t0, 4
	sw $t1,($t0)
	
	addi $t0, $t0, 4
	sw $zero,($t0)
		
	addi $t0, $t0, 4
	sw $t1,($t0)
	
	addi $t0, $t0, 4
	sw $zero,($t0)
	
	j key_wait
	
AcabaTiroInimigo:				#Para a pagar o tiro inimigo
	li $t9, 0				#a flag $t9 que indica se o tiro existe é zerada	
	sw $zero,($s3)				#e os bits coloridos são apagados
	addi $s3, $s3, 8
	sw $zero,($s3)
	addi $s3, $s3, 8
	sw $zero,($s3)
	
	
CriaTiroInimigo:				#Caso o Tiro inimigo não exista
	li $t9, 4				#A flag $t9 é iniciada mostrando a existencia
	la $t1,frameBuffer 
	
	add $t1, $t1, $s1
	subi $t1, $t1, 8
	li $t0, 0x004dff00	
	sw $t0,($t1)
	subi $t1, $t1, 8
	li $t0, 0x004dff00			#apenas é colocada a sequencia de 3 tiros inimigos
	sw $t0,($t1)				#pois a funcao responsavel por mover o tiro é 	MoveTiroInimigo
	subi $t1, $t1, 8
	move $s3, $t1
	li $t0, 0x004dff00	
	sw $t0,($t1)
	j key_wait 
	
	
MoveTiroAmigo:
	beq $s6, $zero, aux			#avalia se o tiro existe baseado na flag $s6
	addi $s6, $s6, 4			#	
	bge $s6, 124, AcabaTiro			#usa a flag $s6 para avaliar se o tiro saiu da tela
	li $t0, 0				#
	sw $t0, ($s2)				#caso o tiro exista e ainda estja na tela ele é movimentado para esquerda
	addi $s2, $s2, 4
	li $t0, 0x000000ff
	sw $t0, ($s2)
	jr $ra
	
	
AcabaTiro:					#caso o tiro tengha chegado ao fim da tela
	li $s6, 0				#a flag $s6 é zerada mostrando que não existe 
	sw $zero, ($s2)				#tiro é apagado
	j key_wait
aux: 
	jr $ra
	
	
GeraTiroAmigo:					#Caso a tecla ' ' seja clicada
	bne $zero, $s6, key_wait		#Avalia se tem algum tiro na tela (Só pode atirar um tiro por vez)
	li $s6, 4				#levanta a  flag mostrando que o tiro existe
	la $t1,frameBuffer 			
	add $t1, $t1 ,$s0
	addi $t1,$t1, 136			
	move $s2, $t1				#O tiro é colocado na frente da nave
	li $t0, 0x000000ff
	sw $t0, ($s2)
	j key_wait
	
	
MoveInimigo:					
	li $v0, 30				#Atualiza o tempo para a movimentação do personagem
    	syscall
    	move $s5, $a0
	li $v0, 42				#A movimentação do inimigo é feita de forma randomica para cim ou para abaixo
	li $a1 , 2
	syscall
	beq $a0, 0, MoveInimigoCima
	beq $a0, 1, MoveInimigoBaixo
	
	
MoveInimigoCima:
	li $t0, 0				#Caso seja para cima, o inimigo é apagado(sobreescrevendo em preto)
	jal DesenhaInimigo
	subi $s1, $s1, 128			#Desenhado um andar a cima
	li $t0, 0x00ff1300
	jal DesenhaInimigo
	j key_wait	
	
	
MoveInimigoBaixo:
	li $t0, 0
	jal DesenhaInimigo			#Caso seja para baixo, o inimigo é apagado(sobreescrevendo em preto
	addi $s1, $s1, 128
	li $t0, 0x00ff1300
	jal DesenhaInimigo			#Desenhado um andar a baixo
	j key_wait
	
	
DesenhaAmigoCima:				#de maneira análoga a inimiga(com excessão do movimento randomico)
	li $t0, 0
	jal DesenhaAmigo
	li $t0, 0x000fff00 
	subi $s0, $s0, 128
	jal DesenhaAmigo
	j key_wait
	
	
DesenhaAmigoBaixo:	
	li $t0, 0				#de maneira análoga a inimiga(com excessão do movimento randomico)
	jal DesenhaAmigo
	li $t0, 0x000fff00 
	addi $s0, $s0, 128
	jal DesenhaAmigo
	j key_wait
	
	
DesenhaAmigo:
    	la $t1,frameBuffer     	# Insere o endereço do inicio do Bitmap


	move $t2, $s0         	# Passa a posição atual da nave


	addu $t1,$t1,$t2	#insere no primeiro pixel da nave
	sw $t0,($t1)		#
	
	
	addi $t1, $t1, 128	#		
	sw $t0,($t1)         	#insere os 2 pixels intermediarios
	addi $t1, $t1, 4	#
	sw $t0,($t1)  		#
	subi $t1, $t1, 4	#
	
	
	addi $t1, $t1, 128	#insere o ultimo pixel
	sw $t0,($t1) 		#
	jr $ra
	
	
DesenhaInimigo:
	la $t1,frameBuffer     	# Insere o endereço do inicio do Bitmap

	move $t2, $s1         	# Passa a posição atual da nave


	addu $t1,$t1,$t2	#insere no primeiro pixel da nave
	sw $t0,($t1)		#
	
	subi $t1, $t1, 4	#insere segundo pixel(ponta)
	sw $t0,($t1)
	
	
	addi $t1, $t1, 132 	#pixel superior
	sw $t0,($t1)
	
	subi $t1, $t1, 256	#pixel inferior
	sw $t0,($t1)
	
	jr $ra
	
	
FinalDerrota:

	li $v0, 4     

   	la $a0,msgDerrota  

    	syscall         
    	
	li	$v0, 10		# Saida para caso de Derrota
	syscall
	
	
FinalVitoria:
	li $v0, 4     

   	la $a0,msgVitoria 

    	syscall  


	li	$v0, 10		# Saida para caso de vitoria
	syscall
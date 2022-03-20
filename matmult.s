# This program implements matMult in assembly to be used in C code
.global matMult
.equ ws, 4
/*
int** matMult(int **a, int num_rows_a, int num_cols_a, int** b, int num_rows_b, int num_cols_b){
	int i, j, k;
	int** C = (int**) malloc(num_rows_a * sizeof(int*));

	for(i = 0; i < num_rows_a; ++i){
        	C[i] = (int*) malloc(num_cols_b * sizeof(int));
		for(j = 0; j < num_cols_b; ++j){
            		C[i][j] = 0;
			for(k = 0; k < num_cols_a; ++k){
				C[i][j] += a[i][k] * b[k][j];
			}
		}
	}
	return C;
}
*/

.text 
matMult:
	prologue:
		push %ebp
		movl %esp, %ebp
		subl $4 * ws, %esp # 4 locals (i, j, k, C)
		#save regs
		push %esi
		push %edi
		push %ebx
		#num_cols_b	7*ws(%ebp)
		#num_rows_b	6*ws(%ebp)
		#B		5*ws(%ebp)
		#num_cols_a	4*ws(%ebp)
		#num_rows_a	3*ws(%ebp)
		#A		2*ws(%ebp)
		#ret address	1*ws(%ebp)
		#ebp: old ebp	(%ebp)
		#i		-1*ws(%ebp)
		#j		-2*ws(%ebp)
		#k		-3*ws(%ebp)
		#C		-4*ws(%ebp)
		#esi
		#edi
		#ebx
		.equ A, 2*ws #(%ebp)
		.equ num_rows_a, 3*ws #(%ebp)
		.equ num_cols_a, 4*ws #(%ebp)
		.equ B, 5*ws #(%ebp)
		.equ num_rows_b, 6*ws #(%ebp)
		.equ num_cols_b, 7*ws #(%ebp)
		.equ i, -1*ws #(%ebp)
		.equ j, -2*ws #(%ebp)
		.equ k, -3*ws #(%ebp)
		.equ C, -4*ws #(%ebp)

		#eax will be i
		#ecx will be j
		#edi will be k
		#edx will be C
		
		#int** c = (int**) malloc(num_rows_a * sizeof(int*));
		movl num_rows_a(%ebp), %eax #eax = num_rows_a
		shll $2, %eax  #eax = num_rows_a * sizeof(int*)) 
		push %eax #place malloc's arguement onto the stack
		call malloc
		addl $1*ws, %esp #clear malloc's argument 
		#eax = (int**)malloc(num_rows * sizeof(int*));
		movl %eax, C(%ebp) 

		#for(i = 0; i < num_rows_a; ++i)
		movl $0, %eax
		malloc_loop:
			cmpl num_rows_a(%ebp), %eax
			jge malloc_loop_end

			#C[i] = (int*)malloc(num_cols_b * sizeof(int));
			movl num_cols_b(%ebp), %edx #edx = num_cols_b
			shll $2, %edx #edx = num_cols_b * sizeof(int)
			push %edx #set argument for malloc
			movl %eax, i(%ebp) #save i 
			call malloc
			addl $1*ws, %esp #clear argument for malloc
			#eax = (int*)malloc(num_cols_b * sizeof(int));
			movl %eax, %edx  #edx = (int*)malloc(num_cols_b * sizeof(int));
			movl i(%ebp), %eax #restore i
			movl C(%ebp), %ecx #ecx = C
			movl %edx, (%ecx, %eax, ws) #C[i] = edx

			incl %eax #++i
			jmp malloc_loop
		malloc_loop_end:
		
		#for(i = 0; i < num_rows_a; ++i)
		movl $0, %eax
		rowA_for_start:#Loop1_start
			#i < num_rows_a
			#i - num_rows_a < 0
			#neg: i - num_rows_a >= 0
			movl %eax, i(%ebp) #Save i so we can use eax for multiplication later
			cmpl num_rows_a(%ebp), %eax
			jge rowA_for_end
						
			#for(j = 0; j < num_cols_b; ++j)
			movl $0, %ecx #j = 0
			colB_for_start:#Loop2_start
				cmpl num_cols_b(%ebp), %ecx
				jge colB_for_end
				#C[i][j] = 0;
				movl C(%ebp), %edx	    #edx = C	
				movl (%edx, %eax, ws), %edx #edx = C[i]
				movl $0, (%edx, %ecx, ws) #C[i][j] = 0
				#for(k = 0; k < num_cols_a; ++k)
				movl $0, %edi #k = 0				
				colA_for_start:
					cmpl num_cols_a(%ebp), %edi
					jge colA_for_end
					# C[i][j] += a[i][k] * b[k][j];
					# *(*(C +i) + j) = *(*(a + i) + k) * *(*(b + k) + j)
														
					#esi will be B[i][j]
					movl B(%ebp), %esi #esi = B
					movl (%esi, %edi, ws), %esi #esi = B[k]
					movl (%esi, %ecx, ws), %esi #esi = B[k][j]

					#ebx will be A[i][j]
					movl A(%ebp), %ebx #ebx = A
					movl (%ebx, %eax, ws), %ebx #ebx = A[i]
					movl (%ebx, %edi, ws), %eax #eax = A[i][k]
										
					mull %esi 	   #eax = eax * esi
					movl i(%ebp), %ebx #ebx = i		

					movl C(%ebp), %edx	    #edx = C	
					movl (%edx, %ebx, ws), %edx #edx = C[i]
					addl %eax, (%edx, %ecx, ws) #C[i][j] += A[i][k] * B[k][j]
					movl %ebx, %eax #eax = i
					incl %edi #++k
					jmp colA_for_start
				colA_for_end:
				incl %ecx #++j
				jmp colB_for_start
			colB_for_end:#Loop2_end
			incl %eax #++i
			jmp rowA_for_start
		rowA_for_end:#Loop1_end
		
		#return C;
		movl C(%ebp), %eax 

	eplilogue:
		#Restore saved args
		pop %ebx		
		pop %esi
		pop %edi
		movl %ebp, %esp
		pop %ebp
		ret













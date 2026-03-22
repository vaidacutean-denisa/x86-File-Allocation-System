.data
    v: .zero 4096            
    N: .long 1024                
    nr_fisiere: .long 0
    descriptor: .long 0                         # descriptorul fisierului curent
    dim: .long 0                                # dimensiunea fisierului

    nr_op: .long 0
    op: .long 0                                                   # indica tipul de operatie

    start: .long 0
    end: .long 0
    nr_fd: .long 0
    nr_blocuri: .long 0
    last_descr: .long 0                                           # folosit pentru a evita cazul in care in input exista acelasi descriptor de mai multe ori
    
    format_Pass: .asciz "%ld: (%ld, %ld)\n"  
    format_FAIL: .asciz "%ld: (0, 0)\n"          
    formatString: .asciz "%ld"
    format_gPass: .asciz "(%ld, %ld)\n"                           # formatul de afisare pentru GET (succes)
    format_gFail: .asciz "(0, 0)\n"

.text

.global main
main:
    pushl $nr_op                                
    pushl $formatString
    call scanf
    addl $8, %esp

    movl nr_op, %ecx
    jmp operatii

afisare_interval:
    pushl end
    pushl start
    pushl descriptor 
    pushl $format_Pass
    call printf                                         # se afiseaza: Descriptor: (a, b)
    addl $16, %esp
    ret

afisare_memorie:
    xor %edi, %edi                                  # indice prin care este parcursa memoria
    xor %ebx, %ebx                                  # descriptorul curent, initial nul

    movl nr_fd, %esi                                # retine numarul de fisiere din memorie; afiseaza (esi) fisiere
    cmp $0, %esi
    je et_end

    parcurgere:
        cmpl N, %edi                             
        jge et_end                                  # am parcurs toata memoria

        movl v(, %edi, 4), %ebx                     # ebx = v[i] (descriptorul curent)
        cmp $0, %ebx
        je continua                                 # cautam blocurile de memorie ocupate (le ignora pe cele nule)

        movl %edi, %eax                             # daca v[i] != 0, incepem alt ciclu de cautare; eax retine inceputul intervalului (capatul inferior)
        inc %edi

    superior:
        cmpl N, %edi
        jge print

        movl v(, %edi, 4), %edx
        cmp %edx, %ebx                              # daca valoarea curenta difera de descriptor, se incheie cautarea
        jne print  

        inc %edi
        jmp superior    

    print:
        subl $1, %edi                               # capatul superior al intervalului = i - 1

        pushl %edi                                  # capatul superior
        pushl %eax                                  # capatul inferior
        pushl %ebx                                  # descriptorul
        pushl $format_Pass
        call printf
        addl $16, %esp

        inc %edi                                    # continua iterarea
        xor %ebx, %ebx                              # se reseaza descriptorul curent

        decl %esi
        cmp $0, %esi
        jne parcurgere                              # continua cautarea urmatoarelor intervale

        jmp et_end

    continua:
        inc %edi
        jmp parcurgere

    et_end:
        ret

operatii:
    pushl $op
    pushl $formatString
    call scanf
    addl $8, %esp

    mov op, %eax
    cmp $1, %eax                                        # testeaza tipul de operatie
    je et_ADD

    mov op, %eax
    cmp $2, %eax
    je GET

    mov op, %eax
    cmp $3, %eax
    je DELETE

    mov op, %eax
    cmp $4, %eax
    je DEFRAGMENTATION

    jmp et_exit

nr_op_dec:
    decl nr_op
    mov nr_op, %ecx
    cmp $0, %ecx
    jne operatii 

et_exit:
    pushl $0
    call fflush
    popl %eax
    
    mov $1, %eax
    xor %ebx, %ebx
    int $0x80    

et_ADD: 
    pushl $nr_fisiere
    pushl $formatString
    call scanf
    addl $8, %esp

    movl nr_fisiere, %ebx

    A_fisier: 
        cmp $0, %ebx
        je nr_op_dec
        
        pushl $descriptor
        pushl $formatString
        call scanf
        addl $8, %esp

        movl last_descr, %eax
        cmpl descriptor, %eax
        je A_exista

        pushl $dim
        pushl $formatString
        call scanf
        addl $8, %esp

        movl dim, %ecx
        cmp $9, %ecx
        jl A_eroare

        addl $7, dim                                    # dimensiunea (rotunjita prin adaos) -> dim = (dim + 7) / 8
        shrl $3, dim

        xor %edi, %edi                                  # index prin care parcurgem tabloul

        movl dim, %esi                                  # pentru a gasi o secventa de zerouri de lungime (esi)

        A_secventa:
            cmpl N, %edi                             
            jge A_eroare

            movl v(, %edi, 4), %eax
            cmp $0, %eax
            jne A_nenul

            inc %edi
            dec %esi

            cmp $0, %esi                                # esi (dimensiunea fisierului) nenul -> continuam cautarea (este necesara o secventa de lungime = esi)
            jne A_secventa

            jmp A_gasit

        A_nenul:                                        # i++
            movl dim, %esi                              # incepem alta cautare
            inc %edi        
            jmp A_secventa

        A_eroare:
            pushl descriptor
            pushl $format_FAIL
            call printf
            addl $8, %esp

            decl %ebx
            cmpl $0, %ebx
            je nr_op_dec

            jmp A_fisier                              # trecem la urmatorul fisier

        A_exista:                                     # descriptor deja existent in memorie
            subl $1, %ebx
            cmpl $0, %ebx
            je operatii

            jmp A_fisier

        A_gasit:
            subl dim, %edi
            incl nr_fd
            decl %ebx

            movl descriptor, %edx
            movl %edx, last_descr

            A_completare:
                movl %edx, v(, %edi, 4)                     # v[edi] = descriptor

                incl nr_blocuri
                inc %edi
                inc %esi
                cmp dim, %esi
                jne A_completare

        movl %edi, %eax
        subl dim, %eax
        subl $1, %edi

        movl %edi, end                              # capatul superior al intervalului
        movl %eax, start                            # capatul inferior al intervalului
        call afisare_interval

        jmp A_fisier

GET:    
    pushl $descriptor
    pushl $formatString
    call scanf
    addl $8, %esp

    xor %edx, %edx                                  # in edx vom rine capatul superior al intervalului (initial este nul)
    movl $4096, %eax                                # in eax vom rine capatul inferior al intervalului (initial este egal cu dim. vectorului)

    cmpl $0, nr_fd                                  # daca nu avem fisiere in memorie
    je G_eroare
             
    xor %esi, %esi                                  # indexul curent  (i)
    xor %ebx, %ebx 

    G_cautare:
        cmp $1025, %esi                             # daca am depasit dimensiunea vectorului (i > 1024); 1025 pentru a putea marca sfarsitul secventei
        jge G_eroare

        movl v(, %esi, 4), %ebx                     # ebx <- v[i] 
        cmp %ebx, descriptor                        # daca nu sunt egale, trecem la urmatoarea iteratie
        jne G_incrementare

        cmp %esi, %eax                              # daca v[i] = descriptor, cautam pozitia minima in care este valabila egalitatea
        jge G_inferior                            

        cmp %esi, %edx                              # cautam ultimul indice pentru care relatia ebx = v[i] = descriptor este adevarata
        jle G_superior

    G_incrementare:
        cmp $0, %edx                                # edx nenul = am gasit intervalul
        jne G_gasit

        inc %esi                                    # edx nul = nu am gasit elemente ale vectorului egale cu descriptorul -> continuam cautarea
        jmp G_cautare

    G_inferior:
        movl %esi, %eax                             # este actualizat capatul inferior
        inc %esi
        jmp G_cautare

    G_superior:
        movl %esi, %edx                             # este actualizat capatul superior
        inc %esi
        jmp G_cautare

    G_eroare:                                       # afisarea in caz ca fisierul nu exista
        push $format_gFail
        call printf
        addl $4, %esp
        jmp nr_op_dec

    G_gasit:                                      # afisarea intervalului gasit
        pushl %edx
        pushl %eax
        pushl $format_gPass
        call printf
        addl $16, %esp

    jmp nr_op_dec

DELETE:
    pushl $descriptor
    pushl $formatString
    call scanf
    addl $8, %esp

    xor %esi, %esi                                  # indicele prin care este parcurs vectorul
    xor %eax, %eax                                  # retine valoarea 1 daca se efectueaza operatia de stergere (variabila semafor)

    cmpl $0, nr_fd
    je nr_op_dec                                    # nu exista niciun fisier in memorie -> nu se poate efectua delete

    DEL_cautare:
        cmp N, %esi
        jge DEL_afisare

        movl v(, %esi, 4), %ebx
        cmp %ebx, descriptor                        # daca v[i] = descriptor, il stergem
        je DEL_sterge

        inc %esi

        cmp $1, %eax                                # conditia de oprire
        je DEL_decrementare                            

        jmp DEL_cautare

    DEL_sterge:
        movl $0, v(, %esi, 4)
        inc %esi

        movl $1, %eax                                # am modificat memoria
        jmp DEL_cautare

    DEL_decrementare:                                # am eliminat un fisier din memorie
        decl nr_fd

    DEL_afisare:
        call afisare_memorie

    jmp nr_op_dec

DEFRAGMENTATION:
    xor %esi, %esi                                  # indicele cu care parcurgem vectorul; verifica toate valorile
    xor %edi, %edi                                  # pointer la spatiile libere (de unde incepe completarea cu valorile nenule)
    movl nr_blocuri, %edx

    DF_parcurgere:
        cmp N, %esi                             
        jge DF_final                                # am parcurs toata memoria

        movl v(, %esi, 4), %eax
        cmp $0, %eax
        je DF_inc_citire

        cmp %esi, %edi
        je DF_inc_both

        movl %eax, v(, %edi, 4)
        movl $0, v(, %esi, 4)

    DF_inc_both:
        inc %edi

    DF_inc_citire:
        inc %esi
        decl %edx 
        cmp $0, %edx
        jne DF_parcurgere

    DF_curata:
        cmp %edi, %esi
        je DF_final

        movl $0, v(, %edi, 4)
        inc %edi
        cmp N, %edi
        jne DF_curata

    DF_final:
        call afisare_memorie
        jmp nr_op_dec

# comenzi:
# tui enable
# la re
# la as
# next
# stepi
# b main
# run



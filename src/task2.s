.data
    m: .zero 4096*4096                                # consideram matricea un tablou unidim. format prin scrierea liniilor secvential (1024 de linii x 1024)
    N: .long 1024
    copie_N: .long 0                                  # folosit pentru a marca multiplii lui N
    nr_fisiere: .long 0
    descriptor: .long 0
    dim: .long 0

    nr_op: .long 0
    op: .long 0

    start: .long 0
    end: .long 0
    nr_fd: .long 0
    nr_blocuri: .long 0
    last_descr: .long 0     
    ordin_seg: .long 1                                                                # indica momentul in care trecem la urmatoarea linie din matrice
    index_linie: .long 0
    index_coloana: .long 0
    J_start: .long 0
    J_end: .long 0

    format_Pass: .asciz "%ld: ((%ld, %ld), (%ld, %ld))\n"
    format_FAIL: .asciz "%ld: ((0, 0), (0, 0))\n"
    format_gPass: .asciz "((%ld, %ld), (%ld, %ld))\n"
    format_gFail: .asciz "((0, 0), (0, 0))\n"
    formatString: .asciz "%ld"

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
    pushl J_end
    pushl index_linie
    pushl J_start
    pushl index_linie
    pushl descriptor
    pushl $format_Pass
    call printf
    addl $24, %esp
    ret

afisare_memorie:
    xor %ebx, %ebx
    xor %edi, %edi

    movl nr_fd, %esi
    cmpl $0, %esi
    je et_end

    movl $1024, copie_N
    movl $0, index_linie
    movl $1, ordin_seg
    movl $0, J_end
    movl $0, J_start

    linie:
        movl index_linie, %ecx
        cmpl N, %ecx
        je et_end

        movl %ecx, index_coloana
        shll $10, index_coloana

        movl index_coloana, %edi

    parcurgere:
        cmpl copie_N, %edi
        je iteratie

        movl m(, %edi, 4), %ebx
        cmp $0, %ebx
        je continua

        movl %edi, J_start
        inc %edi

    superior:
        cmpl copie_N, %edi
        jge print

        movl m(, %edi, 4), %edx
        cmp %edx, %ebx
        jne print

        inc %edi
        jmp superior

    print:
        subl $1, %edi
        xor %edx, %edx
        movl %edi, %eax
        idivl N 
        movl %edx, J_end

        movl J_start, %eax
        xor %edx, %edx
        idivl N
        movl %edx, J_start

        pushl J_end
        pushl index_linie
        pushl J_start
        pushl index_linie
        pushl %ebx
        pushl $format_Pass
        call printf
        addl $24, %esp

        inc %edi
        xor %ebx, %ebx

        decl %esi
        cmp $0, %esi
        jne parcurgere

        jmp et_end

    continua:
        inc %edi
        jmp parcurgere

    iteratie:
        incl index_linie
        incl ordin_seg
        cmpl $1024, ordin_seg
        jge print

        xor %edx, %edx
        movl N, %eax
        imull ordin_seg
        movl %eax, copie_N

        jmp linie

    et_end:
        ret

operatii:
    pushl $op
    pushl $formatString
    call scanf
    addl $8, %esp

    movl op, %eax
    cmp $1, %eax                                        # testeaza tipul de operatie
    je et_ADD

    movl op, %eax
    cmp $2, %eax
    je GET

    movl op, %eax
    cmp $3, %eax
    je DELETE

    movl op, %eax
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

        addl $7, dim                                    
        shrl $3, dim

        movl dim, %esi
        movl $1024, copie_N

        movl $0, index_linie
        movl $1, ordin_seg

        A_linie:
            movl index_linie, %ecx
            cmpl N, %ecx
            je A_eroare

            movl %ecx, index_coloana
            shll $10, index_coloana

            movl index_coloana, %edi

            A_secventa:
                cmpl copie_N, %edi                             
                je A_iteratie

                movl m(, %edi, 4), %eax
                cmp $0, %eax
                jne A_nenul

                inc %edi
                dec %esi

                cmp $0, %esi                                
                jne A_secventa

                jmp A_gasit

            A_nenul:                                        
                movl dim, %esi                             
                inc %edi        
                jmp A_secventa

            A_iteratie:
                movl dim, %esi
                incl index_linie
                incl ordin_seg                                  # retine numarul liniei / segmentului de 1024 de elemente din vector (tabloul format din liniile matricei)
                cmpl $1024, ordin_seg                           # putem completa cu 1024 de elemente pana la segmentul 1023, inclusiv. la 1024*1024 inseamna ca am completat toate segmentele
                jge A_eroare

                xor %edx, %edx
                movl N, %eax
                imull ordin_seg
                movl %eax, copie_N

                jmp A_linie

            A_eroare:
                pushl descriptor
                pushl $format_FAIL
                call printf
                addl $4, %esp

                decl %ebx
                cmpl $0, %ebx
                je nr_op_dec

                jmp A_fisier                              

            A_exista:
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
                    movl %edx, m(, %edi, 4)                     

                    incl nr_blocuri
                    inc %edi
                    inc %esi
                    cmp dim, %esi
                    jne A_completare

                cmpl copie_N, %edi
                je A_margine                                      # fisierul ocupa elementul de pe ultima coloana a matricei

                jmp A_inclus

            A_margine:
                decl %edi                                     # edi va fi incrementat la 1024*k, motiv pentru care restul impartirii va fi 0; pentru a evita greseala, este decrementat
                movl %edi, %eax
                xor %edx, %edx
                idivl N                                       # vectorul este parcurs modular (mod 1024)
                movl %edx, %edi                               # restul impartirii va da indicele coloanei (end)
                incl %edx                                     # pentru a restabili echivalenta (de la prima decrementare); de ex. de la 13 la 15 sunt 3 blocuri (13, 14, 15), dar 15-3 (dim) = 12.
                subl dim, %edx                                # indicele coloanei finale - dimensiune = indicele coloanei de start
                jmp A_afisare

            A_inclus:
                movl %edi, %eax
                xor %edx, %edx
                idivl N                                         # restul (edx) reprezinta indicele coloanei
                movl %edx, %edi
                decl %edi                                       # va retine coordonata J a ultimului bloc de memorie utilizat
                subl dim, %edx                                  # va retine coordonata J a primului bloc             

            A_afisare:
                movl %edi, J_end
                movl %edx, J_start
                call afisare_interval

            jmp A_fisier

GET:
    pushl $descriptor
    pushl $formatString
    call scanf
    addl $8, %esp

    xor %edx, %edx
    movl $4096, %eax
    movl $4096, %ecx
    imul %ecx
    movl %eax, J_start
    movl $0, J_end

    cmpl $0, nr_fd
    je G_eroare

    movl $0, index_linie
    movl $1, ordin_seg
    movl $1025, copie_N                                     # 1025 pentru a putea marca si ultimul element al secventei; altfel, secventa nu ar avea sfarsit

    xor %ebx, %ebx

    G_linie:
        movl index_linie, %ecx
        cmpl N, %ecx
        je G_eroare

        movl %ecx, index_coloana
        shll $10, index_coloana

        movl index_coloana, %edi

        G_cautare:
            cmpl copie_N, %edi
            je G_iteratie

            movl m(, %edi, 4), %ebx
            cmp %ebx, descriptor
            jne G_incrementare

            cmpl J_start, %edi                              # retinem coordonata j a punctului de start
            jle G_inferior

            cmpl J_end, %edi                                # retinem coordonata j a ultimului element (end)
            jge G_superior

        G_iteratie:
            incl index_linie
            incl ordin_seg
            cmpl $1024, ordin_seg
            jge G_eroare

            xor %edx, %edx
            movl N, %eax
            imull ordin_seg
            movl %eax, copie_N
            incl copie_N

            jmp G_linie

        G_incrementare:
            cmpl $0, J_end
            jne G_gasit

            inc %edi
            jmp G_cautare

        G_inferior:
            movl %edi, J_start
            inc %edi
            jmp G_cautare

        G_superior:
            movl %edi, J_end
            inc %edi
            jmp G_cautare
        
        G_eroare:
            push $format_gFail
            call printf
            addl $4, %esp
            jmp nr_op_dec

        G_gasit:
            xor %edx, %edx
            movl J_end, %eax
            idivl N
            movl %edx, J_end

            xor %edx, %edx
            movl J_start, %eax
            idivl N 
            movl %edx, J_start 

            pushl J_end
            pushl index_linie
            pushl J_start
            pushl index_linie
            pushl $format_gPass
            call printf
            addl $20, %esp

    jmp nr_op_dec

DELETE:
    pushl $descriptor
    pushl $formatString
    call scanf
    addl $8, %esp

    xor %ebx, %ebx    
    xor %esi, %esi            

    cmpl $0, nr_fd                          # daca nu exista niciun fisier in memorie
    je nr_op_dec

    movl $0, index_linie
    movl $1, ordin_seg
    movl $1024, copie_N

    DEL_linie:
        movl index_linie, %ecx
        cmpl N, %ecx
        je DEL_afisare                              # am ajuns la finalul tabloului

        movl %ecx, index_coloana
        shll $10, index_coloana

        movl index_coloana, %edi                    # indice prin care parcurgem vectorul

    DEL_cautare:
        cmp copie_N, %edi
        jge DEL_iteratie

        movl m(, %edi, 4), %esi
        cmp %esi, descriptor
        je DEL_sterge

        inc %edi

        cmp $1, %ebx
        je DEL_decrementare

        jmp DEL_cautare
    
    DEL_iteratie:
        incl index_linie
        incl ordin_seg
        cmpl $1024, ordin_seg
        jge DEL_afisare

        xor %edx, %edx
        movl N, %eax
        imull ordin_seg
        movl %eax, copie_N
        
        jmp DEL_linie

    DEL_sterge:
        movl $0, m(, %edi, 4)
        inc %edi

        movl $1, %ebx
        jmp DEL_cautare

    DEL_decrementare:                               # am eliminat un fisier din memorie (a scazut totalul)
        decl nr_fd
    
    DEL_afisare:
        call afisare_memorie

    jmp nr_op_dec

DEFRAGMENTATION:
    xor %esi, %esi
    movl nr_blocuri, %ebx

    movl $0, index_linie
    movl $1, ordin_seg
    movl $1024, copie_N

    DF_linie:
        movl index_linie, %ecx
        cmpl N, %ecx
        je DF_final

        movl %ecx, index_coloana
        shll $10, index_coloana

        movl index_coloana, %edi                    # indice prin care parcurgem tabloul

        DF_parcurgere:
            cmp copie_N, %edi
            jge DF_iteratie

            movl m(, %edi, 4), %eax
            cmp $0, %eax
            jne DF_permutare
            
            inc %edi
            decl %ebx
            cmp $0, %ebx 
            je DF_final

            jmp DF_parcurgere

        DF_iteratie:
            incl index_linie
            incl ordin_seg
            cmpl $1024, ordin_seg
            jge DF_final

            xor %edx, %edx
            movl N, %eax
            imull ordin_seg
            movl %eax, copie_N

            xor %edx, %edx
            movl N, %eax
            imull index_linie
            movl %eax, %esi

            jmp DF_linie

        DF_permutare:
            movl %eax, %ecx
            movl $0, m(, %edi, 4)
            movl %ecx, m(, %esi, 4)
            inc %edi
            inc %esi
            jmp DF_parcurgere

        DF_final:
            call afisare_memorie
            jmp nr_op_dec


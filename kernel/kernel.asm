
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c1c78793          	addi	a5,a5,-996 # 80005c80 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	39a080e7          	jalr	922(ra) # 800024c6 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ef8080e7          	jalr	-264(ra) # 800020cc <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	260080e7          	jalr	608(ra) # 80002470 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	22a080e7          	jalr	554(ra) # 8000251c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e12080e7          	jalr	-494(ra) # 80002258 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9b8080e7          	jalr	-1608(ra) # 80002258 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7a0080e7          	jalr	1952(ra) # 800020cc <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	846080e7          	jalr	-1978(ra) # 8000271a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	de4080e7          	jalr	-540(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fd6080e7          	jalr	-42(ra) # 80001eba <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7a6080e7          	jalr	1958(ra) # 800026f2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7c6080e7          	jalr	1990(ra) # 8000271a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d4e080e7          	jalr	-690(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d5c080e7          	jalr	-676(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f3e080e7          	jalr	-194(ra) # 80002eaa <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	5ce080e7          	jalr	1486(ra) # 80003542 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	578080e7          	jalr	1400(ra) # 800044f4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e5e080e7          	jalr	-418(ra) # 80005de2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a783          	lw	a5,-480(a5) # 80008820 <first.1680>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d28080e7          	jalr	-728(ra) # 80002732 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e007a323          	sw	zero,-506(a5) # 80008820 <first.1680>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	a9e080e7          	jalr	-1378(ra) # 800034c2 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dd878793          	addi	a5,a5,-552 # 80008824 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	b8858593          	addi	a1,a1,-1144 # 80008830 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	20a080e7          	jalr	522(ra) # 80003ef0 <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	76a080e7          	jalr	1898(ra) # 80004586 <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	8be080e7          	jalr	-1858(ra) # 800036fc <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <scheduler>:
{
    80001eba:	715d                	addi	sp,sp,-80
    80001ebc:	e486                	sd	ra,72(sp)
    80001ebe:	e0a2                	sd	s0,64(sp)
    80001ec0:	fc26                	sd	s1,56(sp)
    80001ec2:	f84a                	sd	s2,48(sp)
    80001ec4:	f44e                	sd	s3,40(sp)
    80001ec6:	f052                	sd	s4,32(sp)
    80001ec8:	ec56                	sd	s5,24(sp)
    80001eca:	e85a                	sd	s6,16(sp)
    80001ecc:	e45e                	sd	s7,8(sp)
    80001ece:	e062                	sd	s8,0(sp)
    80001ed0:	0880                	addi	s0,sp,80
  struct proc *p=myproc();
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	ade080e7          	jalr	-1314(ra) # 800019b0 <myproc>
  printf("%d\n",&p->pid);
    80001eda:	03050593          	addi	a1,a0,48
    80001ede:	00006517          	auipc	a0,0x6
    80001ee2:	54a50513          	addi	a0,a0,1354 # 80008428 <states.1717+0x168>
    80001ee6:	ffffe097          	auipc	ra,0xffffe
    80001eea:	6a2080e7          	jalr	1698(ra) # 80000588 <printf>
    80001eee:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef2:	00779c13          	slli	s8,a5,0x7
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	3aa70713          	addi	a4,a4,938 # 800112a0 <pid_lock>
    80001efe:	9762                	add	a4,a4,s8
    80001f00:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f04:	0000f717          	auipc	a4,0xf
    80001f08:	3d470713          	addi	a4,a4,980 # 800112d8 <cpus+0x8>
    80001f0c:	9c3a                	add	s8,s8,a4
      acquire(&tickslock);
    80001f0e:	00015917          	auipc	s2,0x15
    80001f12:	1c290913          	addi	s2,s2,450 # 800170d0 <tickslock>
      while(ticks<=tick_to_stop){
    80001f16:	00007997          	auipc	s3,0x7
    80001f1a:	11e98993          	addi	s3,s3,286 # 80009034 <ticks>
    80001f1e:	00007a17          	auipc	s4,0x7
    80001f22:	112a0a13          	addi	s4,s4,274 # 80009030 <tick_to_stop>
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	0000fb97          	auipc	s7,0xf
    80001f2c:	378b8b93          	addi	s7,s7,888 # 800112a0 <pid_lock>
    80001f30:	9bbe                	add	s7,s7,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f36:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f3a:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	0000f497          	auipc	s1,0xf
    80001f42:	79248493          	addi	s1,s1,1938 # 800116d0 <proc>
      if(p->state == RUNNABLE) {
    80001f46:	4b0d                	li	s6,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	00015a97          	auipc	s5,0x15
    80001f4c:	188a8a93          	addi	s5,s5,392 # 800170d0 <tickslock>
    80001f50:	a811                	j	80001f64 <scheduler+0xaa>
      release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	16848493          	addi	s1,s1,360
    80001f60:	fd5489e3          	beq	s1,s5,80001f32 <scheduler+0x78>
      acquire(&tickslock);
    80001f64:	854a                	mv	a0,s2
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	c7e080e7          	jalr	-898(ra) # 80000be4 <acquire>
      while(ticks<=tick_to_stop){
    80001f6e:	0009a783          	lw	a5,0(s3)
    80001f72:	000a2703          	lw	a4,0(s4)
    80001f76:	00f76763          	bltu	a4,a5,80001f84 <scheduler+0xca>
        ticks++;
    80001f7a:	2785                	addiw	a5,a5,1
      while(ticks<=tick_to_stop){
    80001f7c:	fef77fe3          	bgeu	a4,a5,80001f7a <scheduler+0xc0>
    80001f80:	00f9a023          	sw	a5,0(s3)
      release(&tickslock);
    80001f84:	854a                	mv	a0,s2
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d12080e7          	jalr	-750(ra) # 80000c98 <release>
      acquire(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	c54080e7          	jalr	-940(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f98:	4c9c                	lw	a5,24(s1)
    80001f9a:	fb679ce3          	bne	a5,s6,80001f52 <scheduler+0x98>
        p->state = RUNNING;
    80001f9e:	4791                	li	a5,4
    80001fa0:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    80001fa2:	029bb823          	sd	s1,48(s7)
        swtch(&c->context, &p->context);
    80001fa6:	06048593          	addi	a1,s1,96
    80001faa:	8562                	mv	a0,s8
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	6dc080e7          	jalr	1756(ra) # 80002688 <swtch>
        c->proc = 0;
    80001fb4:	020bb823          	sd	zero,48(s7)
    80001fb8:	bf69                	j	80001f52 <scheduler+0x98>

0000000080001fba <sched>:
{
    80001fba:	7179                	addi	sp,sp,-48
    80001fbc:	f406                	sd	ra,40(sp)
    80001fbe:	f022                	sd	s0,32(sp)
    80001fc0:	ec26                	sd	s1,24(sp)
    80001fc2:	e84a                	sd	s2,16(sp)
    80001fc4:	e44e                	sd	s3,8(sp)
    80001fc6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	9e8080e7          	jalr	-1560(ra) # 800019b0 <myproc>
    80001fd0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	b98080e7          	jalr	-1128(ra) # 80000b6a <holding>
    80001fda:	c93d                	beqz	a0,80002050 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fdc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	0000f717          	auipc	a4,0xf
    80001fe6:	2be70713          	addi	a4,a4,702 # 800112a0 <pid_lock>
    80001fea:	97ba                	add	a5,a5,a4
    80001fec:	0a87a703          	lw	a4,168(a5)
    80001ff0:	4785                	li	a5,1
    80001ff2:	06f71763          	bne	a4,a5,80002060 <sched+0xa6>
  if(p->state == RUNNING)
    80001ff6:	4c98                	lw	a4,24(s1)
    80001ff8:	4791                	li	a5,4
    80001ffa:	06f70b63          	beq	a4,a5,80002070 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002002:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002004:	efb5                	bnez	a5,80002080 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002006:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002008:	0000f917          	auipc	s2,0xf
    8000200c:	29890913          	addi	s2,s2,664 # 800112a0 <pid_lock>
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	97ca                	add	a5,a5,s2
    80002016:	0ac7a983          	lw	s3,172(a5)
    8000201a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	0000f597          	auipc	a1,0xf
    80002024:	2b858593          	addi	a1,a1,696 # 800112d8 <cpus+0x8>
    80002028:	95be                	add	a1,a1,a5
    8000202a:	06048513          	addi	a0,s1,96
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	65a080e7          	jalr	1626(ra) # 80002688 <swtch>
    80002036:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	97ca                	add	a5,a5,s2
    8000203e:	0b37a623          	sw	s3,172(a5)
}
    80002042:	70a2                	ld	ra,40(sp)
    80002044:	7402                	ld	s0,32(sp)
    80002046:	64e2                	ld	s1,24(sp)
    80002048:	6942                	ld	s2,16(sp)
    8000204a:	69a2                	ld	s3,8(sp)
    8000204c:	6145                	addi	sp,sp,48
    8000204e:	8082                	ret
    panic("sched p->lock");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1c850513          	addi	a0,a0,456 # 80008218 <digits+0x1d8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e6080e7          	jalr	1254(ra) # 8000053e <panic>
    panic("sched locks");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1c850513          	addi	a0,a0,456 # 80008228 <digits+0x1e8>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4d6080e7          	jalr	1238(ra) # 8000053e <panic>
    panic("sched running");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1c850513          	addi	a0,a0,456 # 80008238 <digits+0x1f8>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	1c850513          	addi	a0,a0,456 # 80008248 <digits+0x208>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4b6080e7          	jalr	1206(ra) # 8000053e <panic>

0000000080002090 <yield>:
{
    80002090:	1101                	addi	sp,sp,-32
    80002092:	ec06                	sd	ra,24(sp)
    80002094:	e822                	sd	s0,16(sp)
    80002096:	e426                	sd	s1,8(sp)
    80002098:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	916080e7          	jalr	-1770(ra) # 800019b0 <myproc>
    800020a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b40080e7          	jalr	-1216(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020ac:	478d                	li	a5,3
    800020ae:	cc9c                	sw	a5,24(s1)
  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	f0a080e7          	jalr	-246(ra) # 80001fba <sched>
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bde080e7          	jalr	-1058(ra) # 80000c98 <release>
}
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6105                	addi	sp,sp,32
    800020ca:	8082                	ret

00000000800020cc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	1800                	addi	s0,sp,48
    800020da:	89aa                	mv	s3,a0
    800020dc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8d2080e7          	jalr	-1838(ra) # 800019b0 <myproc>
    800020e6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
  release(lk);
    800020f0:	854a                	mv	a0,s2
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020fa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fe:	4789                	li	a5,2
    80002100:	cc9c                	sw	a5,24(s1)

  sched();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	eb8080e7          	jalr	-328(ra) # 80001fba <sched>

  // Tidy up.
  p->chan = 0;
    8000210a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b88080e7          	jalr	-1144(ra) # 80000c98 <release>
  acquire(lk);
    80002118:	854a                	mv	a0,s2
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	aca080e7          	jalr	-1334(ra) # 80000be4 <acquire>
}
    80002122:	70a2                	ld	ra,40(sp)
    80002124:	7402                	ld	s0,32(sp)
    80002126:	64e2                	ld	s1,24(sp)
    80002128:	6942                	ld	s2,16(sp)
    8000212a:	69a2                	ld	s3,8(sp)
    8000212c:	6145                	addi	sp,sp,48
    8000212e:	8082                	ret

0000000080002130 <wait>:
{
    80002130:	715d                	addi	sp,sp,-80
    80002132:	e486                	sd	ra,72(sp)
    80002134:	e0a2                	sd	s0,64(sp)
    80002136:	fc26                	sd	s1,56(sp)
    80002138:	f84a                	sd	s2,48(sp)
    8000213a:	f44e                	sd	s3,40(sp)
    8000213c:	f052                	sd	s4,32(sp)
    8000213e:	ec56                	sd	s5,24(sp)
    80002140:	e85a                	sd	s6,16(sp)
    80002142:	e45e                	sd	s7,8(sp)
    80002144:	e062                	sd	s8,0(sp)
    80002146:	0880                	addi	s0,sp,80
    80002148:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	866080e7          	jalr	-1946(ra) # 800019b0 <myproc>
    80002152:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002154:	0000f517          	auipc	a0,0xf
    80002158:	16450513          	addi	a0,a0,356 # 800112b8 <wait_lock>
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a88080e7          	jalr	-1400(ra) # 80000be4 <acquire>
    havekids = 0;
    80002164:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002166:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002168:	00015997          	auipc	s3,0x15
    8000216c:	f6898993          	addi	s3,s3,-152 # 800170d0 <tickslock>
        havekids = 1;
    80002170:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002172:	0000fc17          	auipc	s8,0xf
    80002176:	146c0c13          	addi	s8,s8,326 # 800112b8 <wait_lock>
    havekids = 0;
    8000217a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000217c:	0000f497          	auipc	s1,0xf
    80002180:	55448493          	addi	s1,s1,1364 # 800116d0 <proc>
    80002184:	a0bd                	j	800021f2 <wait+0xc2>
          pid = np->pid;
    80002186:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000218a:	000b0e63          	beqz	s6,800021a6 <wait+0x76>
    8000218e:	4691                	li	a3,4
    80002190:	02c48613          	addi	a2,s1,44
    80002194:	85da                	mv	a1,s6
    80002196:	05093503          	ld	a0,80(s2)
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	4d8080e7          	jalr	1240(ra) # 80001672 <copyout>
    800021a2:	02054563          	bltz	a0,800021cc <wait+0x9c>
          freeproc(np);
    800021a6:	8526                	mv	a0,s1
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	9ba080e7          	jalr	-1606(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
          release(&wait_lock);
    800021ba:	0000f517          	auipc	a0,0xf
    800021be:	0fe50513          	addi	a0,a0,254 # 800112b8 <wait_lock>
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
          return pid;
    800021ca:	a09d                	j	80002230 <wait+0x100>
            release(&np->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
            release(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
            return -1;
    800021e6:	59fd                	li	s3,-1
    800021e8:	a0a1                	j	80002230 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021ea:	16848493          	addi	s1,s1,360
    800021ee:	03348463          	beq	s1,s3,80002216 <wait+0xe6>
      if(np->parent == p){
    800021f2:	7c9c                	ld	a5,56(s1)
    800021f4:	ff279be3          	bne	a5,s2,800021ea <wait+0xba>
        acquire(&np->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	9ea080e7          	jalr	-1558(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002202:	4c9c                	lw	a5,24(s1)
    80002204:	f94781e3          	beq	a5,s4,80002186 <wait+0x56>
        release(&np->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
        havekids = 1;
    80002212:	8756                	mv	a4,s5
    80002214:	bfd9                	j	800021ea <wait+0xba>
    if(!havekids || p->killed){
    80002216:	c701                	beqz	a4,8000221e <wait+0xee>
    80002218:	02892783          	lw	a5,40(s2)
    8000221c:	c79d                	beqz	a5,8000224a <wait+0x11a>
      release(&wait_lock);
    8000221e:	0000f517          	auipc	a0,0xf
    80002222:	09a50513          	addi	a0,a0,154 # 800112b8 <wait_lock>
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
      return -1;
    8000222e:	59fd                	li	s3,-1
}
    80002230:	854e                	mv	a0,s3
    80002232:	60a6                	ld	ra,72(sp)
    80002234:	6406                	ld	s0,64(sp)
    80002236:	74e2                	ld	s1,56(sp)
    80002238:	7942                	ld	s2,48(sp)
    8000223a:	79a2                	ld	s3,40(sp)
    8000223c:	7a02                	ld	s4,32(sp)
    8000223e:	6ae2                	ld	s5,24(sp)
    80002240:	6b42                	ld	s6,16(sp)
    80002242:	6ba2                	ld	s7,8(sp)
    80002244:	6c02                	ld	s8,0(sp)
    80002246:	6161                	addi	sp,sp,80
    80002248:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000224a:	85e2                	mv	a1,s8
    8000224c:	854a                	mv	a0,s2
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	e7e080e7          	jalr	-386(ra) # 800020cc <sleep>
    havekids = 0;
    80002256:	b715                	j	8000217a <wait+0x4a>

0000000080002258 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002258:	7139                	addi	sp,sp,-64
    8000225a:	fc06                	sd	ra,56(sp)
    8000225c:	f822                	sd	s0,48(sp)
    8000225e:	f426                	sd	s1,40(sp)
    80002260:	f04a                	sd	s2,32(sp)
    80002262:	ec4e                	sd	s3,24(sp)
    80002264:	e852                	sd	s4,16(sp)
    80002266:	e456                	sd	s5,8(sp)
    80002268:	0080                	addi	s0,sp,64
    8000226a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000226c:	0000f497          	auipc	s1,0xf
    80002270:	46448493          	addi	s1,s1,1124 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002274:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002276:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002278:	00015917          	auipc	s2,0x15
    8000227c:	e5890913          	addi	s2,s2,-424 # 800170d0 <tickslock>
    80002280:	a821                	j	80002298 <wakeup+0x40>
        p->state = RUNNABLE;
    80002282:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a10080e7          	jalr	-1520(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002290:	16848493          	addi	s1,s1,360
    80002294:	03248463          	beq	s1,s2,800022bc <wakeup+0x64>
    if(p != myproc()){
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	718080e7          	jalr	1816(ra) # 800019b0 <myproc>
    800022a0:	fea488e3          	beq	s1,a0,80002290 <wakeup+0x38>
      acquire(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022ae:	4c9c                	lw	a5,24(s1)
    800022b0:	fd379be3          	bne	a5,s3,80002286 <wakeup+0x2e>
    800022b4:	709c                	ld	a5,32(s1)
    800022b6:	fd4798e3          	bne	a5,s4,80002286 <wakeup+0x2e>
    800022ba:	b7e1                	j	80002282 <wakeup+0x2a>
    }
  }
}
    800022bc:	70e2                	ld	ra,56(sp)
    800022be:	7442                	ld	s0,48(sp)
    800022c0:	74a2                	ld	s1,40(sp)
    800022c2:	7902                	ld	s2,32(sp)
    800022c4:	69e2                	ld	s3,24(sp)
    800022c6:	6a42                	ld	s4,16(sp)
    800022c8:	6aa2                	ld	s5,8(sp)
    800022ca:	6121                	addi	sp,sp,64
    800022cc:	8082                	ret

00000000800022ce <reparent>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	e052                	sd	s4,0(sp)
    800022dc:	1800                	addi	s0,sp,48
    800022de:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022e0:	0000f497          	auipc	s1,0xf
    800022e4:	3f048493          	addi	s1,s1,1008 # 800116d0 <proc>
      pp->parent = initproc;
    800022e8:	00007a17          	auipc	s4,0x7
    800022ec:	d40a0a13          	addi	s4,s4,-704 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	de098993          	addi	s3,s3,-544 # 800170d0 <tickslock>
    800022f8:	a029                	j	80002302 <reparent+0x34>
    800022fa:	16848493          	addi	s1,s1,360
    800022fe:	01348d63          	beq	s1,s3,80002318 <reparent+0x4a>
    if(pp->parent == p){
    80002302:	7c9c                	ld	a5,56(s1)
    80002304:	ff279be3          	bne	a5,s2,800022fa <reparent+0x2c>
      pp->parent = initproc;
    80002308:	000a3503          	ld	a0,0(s4)
    8000230c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	f4a080e7          	jalr	-182(ra) # 80002258 <wakeup>
    80002316:	b7d5                	j	800022fa <reparent+0x2c>
}
    80002318:	70a2                	ld	ra,40(sp)
    8000231a:	7402                	ld	s0,32(sp)
    8000231c:	64e2                	ld	s1,24(sp)
    8000231e:	6942                	ld	s2,16(sp)
    80002320:	69a2                	ld	s3,8(sp)
    80002322:	6a02                	ld	s4,0(sp)
    80002324:	6145                	addi	sp,sp,48
    80002326:	8082                	ret

0000000080002328 <exit>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	e052                	sd	s4,0(sp)
    80002336:	1800                	addi	s0,sp,48
    80002338:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	676080e7          	jalr	1654(ra) # 800019b0 <myproc>
    80002342:	89aa                	mv	s3,a0
  if(p == initproc)
    80002344:	00007797          	auipc	a5,0x7
    80002348:	ce47b783          	ld	a5,-796(a5) # 80009028 <initproc>
    8000234c:	0d050493          	addi	s1,a0,208
    80002350:	15050913          	addi	s2,a0,336
    80002354:	02a79363          	bne	a5,a0,8000237a <exit+0x52>
    panic("init exiting");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f0850513          	addi	a0,a0,-248 # 80008260 <digits+0x220>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
      fileclose(f);
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	270080e7          	jalr	624(ra) # 800045d8 <fileclose>
      p->ofile[fd] = 0;
    80002370:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002374:	04a1                	addi	s1,s1,8
    80002376:	01248563          	beq	s1,s2,80002380 <exit+0x58>
    if(p->ofile[fd]){
    8000237a:	6088                	ld	a0,0(s1)
    8000237c:	f575                	bnez	a0,80002368 <exit+0x40>
    8000237e:	bfdd                	j	80002374 <exit+0x4c>
  begin_op();
    80002380:	00002097          	auipc	ra,0x2
    80002384:	d8c080e7          	jalr	-628(ra) # 8000410c <begin_op>
  iput(p->cwd);
    80002388:	1509b503          	ld	a0,336(s3)
    8000238c:	00001097          	auipc	ra,0x1
    80002390:	568080e7          	jalr	1384(ra) # 800038f4 <iput>
  end_op();
    80002394:	00002097          	auipc	ra,0x2
    80002398:	df8080e7          	jalr	-520(ra) # 8000418c <end_op>
  p->cwd = 0;
    8000239c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	f1848493          	addi	s1,s1,-232 # 800112b8 <wait_lock>
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  reparent(p);
    800023b2:	854e                	mv	a0,s3
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	f1a080e7          	jalr	-230(ra) # 800022ce <reparent>
  wakeup(p->parent);
    800023bc:	0389b503          	ld	a0,56(s3)
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	e98080e7          	jalr	-360(ra) # 80002258 <wakeup>
  acquire(&p->lock);
    800023c8:	854e                	mv	a0,s3
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023d2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023d6:	4795                	li	a5,5
    800023d8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
  sched();
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	bd4080e7          	jalr	-1068(ra) # 80001fba <sched>
  panic("zombie exit");
    800023ee:	00006517          	auipc	a0,0x6
    800023f2:	e8250513          	addi	a0,a0,-382 # 80008270 <digits+0x230>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800023fe <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000240e:	0000f497          	auipc	s1,0xf
    80002412:	2c248493          	addi	s1,s1,706 # 800116d0 <proc>
    80002416:	00015997          	auipc	s3,0x15
    8000241a:	cba98993          	addi	s3,s3,-838 # 800170d0 <tickslock>
    acquire(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002428:	589c                	lw	a5,48(s1)
    8000242a:	01278d63          	beq	a5,s2,80002444 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002438:	16848493          	addi	s1,s1,360
    8000243c:	ff3491e3          	bne	s1,s3,8000241e <kill+0x20>
  }
  return -1;
    80002440:	557d                	li	a0,-1
    80002442:	a829                	j	8000245c <kill+0x5e>
      p->killed = 1;
    80002444:	4785                	li	a5,1
    80002446:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002448:	4c98                	lw	a4,24(s1)
    8000244a:	4789                	li	a5,2
    8000244c:	00f70f63          	beq	a4,a5,8000246a <kill+0x6c>
      release(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	846080e7          	jalr	-1978(ra) # 80000c98 <release>
      return 0;
    8000245a:	4501                	li	a0,0
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6145                	addi	sp,sp,48
    80002468:	8082                	ret
        p->state = RUNNABLE;
    8000246a:	478d                	li	a5,3
    8000246c:	cc9c                	sw	a5,24(s1)
    8000246e:	b7cd                	j	80002450 <kill+0x52>

0000000080002470 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002470:	7179                	addi	sp,sp,-48
    80002472:	f406                	sd	ra,40(sp)
    80002474:	f022                	sd	s0,32(sp)
    80002476:	ec26                	sd	s1,24(sp)
    80002478:	e84a                	sd	s2,16(sp)
    8000247a:	e44e                	sd	s3,8(sp)
    8000247c:	e052                	sd	s4,0(sp)
    8000247e:	1800                	addi	s0,sp,48
    80002480:	84aa                	mv	s1,a0
    80002482:	892e                	mv	s2,a1
    80002484:	89b2                	mv	s3,a2
    80002486:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	528080e7          	jalr	1320(ra) # 800019b0 <myproc>
  if(user_dst){
    80002490:	c08d                	beqz	s1,800024b2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002492:	86d2                	mv	a3,s4
    80002494:	864e                	mv	a2,s3
    80002496:	85ca                	mv	a1,s2
    80002498:	6928                	ld	a0,80(a0)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	1d8080e7          	jalr	472(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a2:	70a2                	ld	ra,40(sp)
    800024a4:	7402                	ld	s0,32(sp)
    800024a6:	64e2                	ld	s1,24(sp)
    800024a8:	6942                	ld	s2,16(sp)
    800024aa:	69a2                	ld	s3,8(sp)
    800024ac:	6a02                	ld	s4,0(sp)
    800024ae:	6145                	addi	sp,sp,48
    800024b0:	8082                	ret
    memmove((char *)dst, src, len);
    800024b2:	000a061b          	sext.w	a2,s4
    800024b6:	85ce                	mv	a1,s3
    800024b8:	854a                	mv	a0,s2
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	886080e7          	jalr	-1914(ra) # 80000d40 <memmove>
    return 0;
    800024c2:	8526                	mv	a0,s1
    800024c4:	bff9                	j	800024a2 <either_copyout+0x32>

00000000800024c6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c6:	7179                	addi	sp,sp,-48
    800024c8:	f406                	sd	ra,40(sp)
    800024ca:	f022                	sd	s0,32(sp)
    800024cc:	ec26                	sd	s1,24(sp)
    800024ce:	e84a                	sd	s2,16(sp)
    800024d0:	e44e                	sd	s3,8(sp)
    800024d2:	e052                	sd	s4,0(sp)
    800024d4:	1800                	addi	s0,sp,48
    800024d6:	892a                	mv	s2,a0
    800024d8:	84ae                	mv	s1,a1
    800024da:	89b2                	mv	s3,a2
    800024dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	4d2080e7          	jalr	1234(ra) # 800019b0 <myproc>
  if(user_src){
    800024e6:	c08d                	beqz	s1,80002508 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e8:	86d2                	mv	a3,s4
    800024ea:	864e                	mv	a2,s3
    800024ec:	85ca                	mv	a1,s2
    800024ee:	6928                	ld	a0,80(a0)
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	20e080e7          	jalr	526(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6a02                	ld	s4,0(sp)
    80002504:	6145                	addi	sp,sp,48
    80002506:	8082                	ret
    memmove(dst, (char*)src, len);
    80002508:	000a061b          	sext.w	a2,s4
    8000250c:	85ce                	mv	a1,s3
    8000250e:	854a                	mv	a0,s2
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	830080e7          	jalr	-2000(ra) # 80000d40 <memmove>
    return 0;
    80002518:	8526                	mv	a0,s1
    8000251a:	bff9                	j	800024f8 <either_copyin+0x32>

000000008000251c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000251c:	715d                	addi	sp,sp,-80
    8000251e:	e486                	sd	ra,72(sp)
    80002520:	e0a2                	sd	s0,64(sp)
    80002522:	fc26                	sd	s1,56(sp)
    80002524:	f84a                	sd	s2,48(sp)
    80002526:	f44e                	sd	s3,40(sp)
    80002528:	f052                	sd	s4,32(sp)
    8000252a:	ec56                	sd	s5,24(sp)
    8000252c:	e85a                	sd	s6,16(sp)
    8000252e:	e45e                	sd	s7,8(sp)
    80002530:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002532:	00006517          	auipc	a0,0x6
    80002536:	b9650513          	addi	a0,a0,-1130 # 800080c8 <digits+0x88>
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	04e080e7          	jalr	78(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002542:	0000f497          	auipc	s1,0xf
    80002546:	2e648493          	addi	s1,s1,742 # 80011828 <proc+0x158>
    8000254a:	00015917          	auipc	s2,0x15
    8000254e:	cde90913          	addi	s2,s2,-802 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002552:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002554:	00006997          	auipc	s3,0x6
    80002558:	d2c98993          	addi	s3,s3,-724 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000255c:	00006a97          	auipc	s5,0x6
    80002560:	d2ca8a93          	addi	s5,s5,-724 # 80008288 <digits+0x248>
    printf("\n");
    80002564:	00006a17          	auipc	s4,0x6
    80002568:	b64a0a13          	addi	s4,s4,-1180 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256c:	00006b97          	auipc	s7,0x6
    80002570:	d54b8b93          	addi	s7,s7,-684 # 800082c0 <states.1717>
    80002574:	a00d                	j	80002596 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002576:	ed86a583          	lw	a1,-296(a3)
    8000257a:	8556                	mv	a0,s5
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	00c080e7          	jalr	12(ra) # 80000588 <printf>
    printf("\n");
    80002584:	8552                	mv	a0,s4
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	002080e7          	jalr	2(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258e:	16848493          	addi	s1,s1,360
    80002592:	03248163          	beq	s1,s2,800025b4 <procdump+0x98>
    if(p->state == UNUSED)
    80002596:	86a6                	mv	a3,s1
    80002598:	ec04a783          	lw	a5,-320(s1)
    8000259c:	dbed                	beqz	a5,8000258e <procdump+0x72>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a0:	fcfb6be3          	bltu	s6,a5,80002576 <procdump+0x5a>
    800025a4:	1782                	slli	a5,a5,0x20
    800025a6:	9381                	srli	a5,a5,0x20
    800025a8:	078e                	slli	a5,a5,0x3
    800025aa:	97de                	add	a5,a5,s7
    800025ac:	6390                	ld	a2,0(a5)
    800025ae:	f661                	bnez	a2,80002576 <procdump+0x5a>
      state = "???";
    800025b0:	864e                	mv	a2,s3
    800025b2:	b7d1                	j	80002576 <procdump+0x5a>
  }
}
    800025b4:	60a6                	ld	ra,72(sp)
    800025b6:	6406                	ld	s0,64(sp)
    800025b8:	74e2                	ld	s1,56(sp)
    800025ba:	7942                	ld	s2,48(sp)
    800025bc:	79a2                	ld	s3,40(sp)
    800025be:	7a02                	ld	s4,32(sp)
    800025c0:	6ae2                	ld	s5,24(sp)
    800025c2:	6b42                	ld	s6,16(sp)
    800025c4:	6ba2                	ld	s7,8(sp)
    800025c6:	6161                	addi	sp,sp,80
    800025c8:	8082                	ret

00000000800025ca <pause_system>:

int
pause_system(int seconds){
    800025ca:	1101                	addi	sp,sp,-32
    800025cc:	ec06                	sd	ra,24(sp)
    800025ce:	e822                	sd	s0,16(sp)
    800025d0:	e426                	sd	s1,8(sp)
    800025d2:	1000                	addi	s0,sp,32
    800025d4:	84aa                	mv	s1,a0
  acquire(&tickslock);
    800025d6:	00015517          	auipc	a0,0x15
    800025da:	afa50513          	addi	a0,a0,-1286 # 800170d0 <tickslock>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	606080e7          	jalr	1542(ra) # 80000be4 <acquire>
  tick_to_stop= ticks+(seconds*100000000);
    800025e6:	05f5e537          	lui	a0,0x5f5e
    800025ea:	1005051b          	addiw	a0,a0,256
    800025ee:	02a484bb          	mulw	s1,s1,a0
    800025f2:	00007517          	auipc	a0,0x7
    800025f6:	a4252503          	lw	a0,-1470(a0) # 80009034 <ticks>
    800025fa:	9ca9                	addw	s1,s1,a0
    800025fc:	00007797          	auipc	a5,0x7
    80002600:	a297aa23          	sw	s1,-1484(a5) # 80009030 <tick_to_stop>
  release(&tickslock);
    80002604:	00015517          	auipc	a0,0x15
    80002608:	acc50513          	addi	a0,a0,-1332 # 800170d0 <tickslock>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
  yield();
    80002614:	00000097          	auipc	ra,0x0
    80002618:	a7c080e7          	jalr	-1412(ra) # 80002090 <yield>
  return 0;
}
    8000261c:	4501                	li	a0,0
    8000261e:	60e2                	ld	ra,24(sp)
    80002620:	6442                	ld	s0,16(sp)
    80002622:	64a2                	ld	s1,8(sp)
    80002624:	6105                	addi	sp,sp,32
    80002626:	8082                	ret

0000000080002628 <kill_system>:

void
kill_system(void){
    80002628:	7179                	addi	sp,sp,-48
    8000262a:	f406                	sd	ra,40(sp)
    8000262c:	f022                	sd	s0,32(sp)
    8000262e:	ec26                	sd	s1,24(sp)
    80002630:	e84a                	sd	s2,16(sp)
    80002632:	e44e                	sd	s3,8(sp)
    80002634:	e052                	sd	s4,0(sp)
    80002636:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    80002638:	0000f497          	auipc	s1,0xf
    8000263c:	09848493          	addi	s1,s1,152 # 800116d0 <proc>
  acquire(&p->lock);
  if((p->pid) != 48){
    80002640:	03000993          	li	s3,48
    p->killed=1;
    80002644:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002646:	00015917          	auipc	s2,0x15
    8000264a:	a8a90913          	addi	s2,s2,-1398 # 800170d0 <tickslock>
    8000264e:	a821                	j	80002666 <kill_system+0x3e>
    p->killed=1;
    80002650:	0344a423          	sw	s4,40(s1)
    }
  release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000265e:	16848493          	addi	s1,s1,360
    80002662:	01248b63          	beq	s1,s2,80002678 <kill_system+0x50>
  acquire(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	57c080e7          	jalr	1404(ra) # 80000be4 <acquire>
  if((p->pid) != 48){
    80002670:	589c                	lw	a5,48(s1)
    80002672:	fd379fe3          	bne	a5,s3,80002650 <kill_system+0x28>
    80002676:	bff9                	j	80002654 <kill_system+0x2c>
  }
}
    80002678:	70a2                	ld	ra,40(sp)
    8000267a:	7402                	ld	s0,32(sp)
    8000267c:	64e2                	ld	s1,24(sp)
    8000267e:	6942                	ld	s2,16(sp)
    80002680:	69a2                	ld	s3,8(sp)
    80002682:	6a02                	ld	s4,0(sp)
    80002684:	6145                	addi	sp,sp,48
    80002686:	8082                	ret

0000000080002688 <swtch>:
    80002688:	00153023          	sd	ra,0(a0)
    8000268c:	00253423          	sd	sp,8(a0)
    80002690:	e900                	sd	s0,16(a0)
    80002692:	ed04                	sd	s1,24(a0)
    80002694:	03253023          	sd	s2,32(a0)
    80002698:	03353423          	sd	s3,40(a0)
    8000269c:	03453823          	sd	s4,48(a0)
    800026a0:	03553c23          	sd	s5,56(a0)
    800026a4:	05653023          	sd	s6,64(a0)
    800026a8:	05753423          	sd	s7,72(a0)
    800026ac:	05853823          	sd	s8,80(a0)
    800026b0:	05953c23          	sd	s9,88(a0)
    800026b4:	07a53023          	sd	s10,96(a0)
    800026b8:	07b53423          	sd	s11,104(a0)
    800026bc:	0005b083          	ld	ra,0(a1)
    800026c0:	0085b103          	ld	sp,8(a1)
    800026c4:	6980                	ld	s0,16(a1)
    800026c6:	6d84                	ld	s1,24(a1)
    800026c8:	0205b903          	ld	s2,32(a1)
    800026cc:	0285b983          	ld	s3,40(a1)
    800026d0:	0305ba03          	ld	s4,48(a1)
    800026d4:	0385ba83          	ld	s5,56(a1)
    800026d8:	0405bb03          	ld	s6,64(a1)
    800026dc:	0485bb83          	ld	s7,72(a1)
    800026e0:	0505bc03          	ld	s8,80(a1)
    800026e4:	0585bc83          	ld	s9,88(a1)
    800026e8:	0605bd03          	ld	s10,96(a1)
    800026ec:	0685bd83          	ld	s11,104(a1)
    800026f0:	8082                	ret

00000000800026f2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f2:	1141                	addi	sp,sp,-16
    800026f4:	e406                	sd	ra,8(sp)
    800026f6:	e022                	sd	s0,0(sp)
    800026f8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fa:	00006597          	auipc	a1,0x6
    800026fe:	bf658593          	addi	a1,a1,-1034 # 800082f0 <states.1717+0x30>
    80002702:	00015517          	auipc	a0,0x15
    80002706:	9ce50513          	addi	a0,a0,-1586 # 800170d0 <tickslock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	44a080e7          	jalr	1098(ra) # 80000b54 <initlock>
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e422                	sd	s0,8(sp)
    8000271e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	00003797          	auipc	a5,0x3
    80002724:	4d078793          	addi	a5,a5,1232 # 80005bf0 <kernelvec>
    80002728:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272c:	6422                	ld	s0,8(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	276080e7          	jalr	630(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002742:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002746:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274c:	00005617          	auipc	a2,0x5
    80002750:	8b460613          	addi	a2,a2,-1868 # 80007000 <_trampoline>
    80002754:	00005697          	auipc	a3,0x5
    80002758:	8ac68693          	addi	a3,a3,-1876 # 80007000 <_trampoline>
    8000275c:	8e91                	sub	a3,a3,a2
    8000275e:	040007b7          	lui	a5,0x4000
    80002762:	17fd                	addi	a5,a5,-1
    80002764:	07b2                	slli	a5,a5,0xc
    80002766:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002768:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000276e:	180026f3          	csrr	a3,satp
    80002772:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002774:	6d38                	ld	a4,88(a0)
    80002776:	6134                	ld	a3,64(a0)
    80002778:	6585                	lui	a1,0x1
    8000277a:	96ae                	add	a3,a3,a1
    8000277c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000277e:	6d38                	ld	a4,88(a0)
    80002780:	00000697          	auipc	a3,0x0
    80002784:	13868693          	addi	a3,a3,312 # 800028b8 <usertrap>
    80002788:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278c:	8692                	mv	a3,tp
    8000278e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002794:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002798:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a2:	6f18                	ld	a4,24(a4)
    800027a4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027a8:	692c                	ld	a1,80(a0)
    800027aa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ac:	00005717          	auipc	a4,0x5
    800027b0:	8e470713          	addi	a4,a4,-1820 # 80007090 <userret>
    800027b4:	8f11                	sub	a4,a4,a2
    800027b6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027b8:	577d                	li	a4,-1
    800027ba:	177e                	slli	a4,a4,0x3f
    800027bc:	8dd9                	or	a1,a1,a4
    800027be:	02000537          	lui	a0,0x2000
    800027c2:	157d                	addi	a0,a0,-1
    800027c4:	0536                	slli	a0,a0,0xd
    800027c6:	9782                	jalr	a5
}
    800027c8:	60a2                	ld	ra,8(sp)
    800027ca:	6402                	ld	s0,0(sp)
    800027cc:	0141                	addi	sp,sp,16
    800027ce:	8082                	ret

00000000800027d0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d0:	1101                	addi	sp,sp,-32
    800027d2:	ec06                	sd	ra,24(sp)
    800027d4:	e822                	sd	s0,16(sp)
    800027d6:	e426                	sd	s1,8(sp)
    800027d8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027da:	00015497          	auipc	s1,0x15
    800027de:	8f648493          	addi	s1,s1,-1802 # 800170d0 <tickslock>
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	400080e7          	jalr	1024(ra) # 80000be4 <acquire>
  ticks++;
    800027ec:	00007517          	auipc	a0,0x7
    800027f0:	84850513          	addi	a0,a0,-1976 # 80009034 <ticks>
    800027f4:	411c                	lw	a5,0(a0)
    800027f6:	2785                	addiw	a5,a5,1
    800027f8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	a5e080e7          	jalr	-1442(ra) # 80002258 <wakeup>
  release(&tickslock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	494080e7          	jalr	1172(ra) # 80000c98 <release>
}
    8000280c:	60e2                	ld	ra,24(sp)
    8000280e:	6442                	ld	s0,16(sp)
    80002810:	64a2                	ld	s1,8(sp)
    80002812:	6105                	addi	sp,sp,32
    80002814:	8082                	ret

0000000080002816 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002816:	1101                	addi	sp,sp,-32
    80002818:	ec06                	sd	ra,24(sp)
    8000281a:	e822                	sd	s0,16(sp)
    8000281c:	e426                	sd	s1,8(sp)
    8000281e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002820:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002824:	00074d63          	bltz	a4,8000283e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002828:	57fd                	li	a5,-1
    8000282a:	17fe                	slli	a5,a5,0x3f
    8000282c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000282e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002830:	06f70363          	beq	a4,a5,80002896 <devintr+0x80>
  }
}
    80002834:	60e2                	ld	ra,24(sp)
    80002836:	6442                	ld	s0,16(sp)
    80002838:	64a2                	ld	s1,8(sp)
    8000283a:	6105                	addi	sp,sp,32
    8000283c:	8082                	ret
     (scause & 0xff) == 9){
    8000283e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002842:	46a5                	li	a3,9
    80002844:	fed792e3          	bne	a5,a3,80002828 <devintr+0x12>
    int irq = plic_claim();
    80002848:	00003097          	auipc	ra,0x3
    8000284c:	4b0080e7          	jalr	1200(ra) # 80005cf8 <plic_claim>
    80002850:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002852:	47a9                	li	a5,10
    80002854:	02f50763          	beq	a0,a5,80002882 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002858:	4785                	li	a5,1
    8000285a:	02f50963          	beq	a0,a5,8000288c <devintr+0x76>
    return 1;
    8000285e:	4505                	li	a0,1
    } else if(irq){
    80002860:	d8f1                	beqz	s1,80002834 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002862:	85a6                	mv	a1,s1
    80002864:	00006517          	auipc	a0,0x6
    80002868:	a9450513          	addi	a0,a0,-1388 # 800082f8 <states.1717+0x38>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	d1c080e7          	jalr	-740(ra) # 80000588 <printf>
      plic_complete(irq);
    80002874:	8526                	mv	a0,s1
    80002876:	00003097          	auipc	ra,0x3
    8000287a:	4a6080e7          	jalr	1190(ra) # 80005d1c <plic_complete>
    return 1;
    8000287e:	4505                	li	a0,1
    80002880:	bf55                	j	80002834 <devintr+0x1e>
      uartintr();
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	126080e7          	jalr	294(ra) # 800009a8 <uartintr>
    8000288a:	b7ed                	j	80002874 <devintr+0x5e>
      virtio_disk_intr();
    8000288c:	00004097          	auipc	ra,0x4
    80002890:	970080e7          	jalr	-1680(ra) # 800061fc <virtio_disk_intr>
    80002894:	b7c5                	j	80002874 <devintr+0x5e>
    if(cpuid() == 0){
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	0ee080e7          	jalr	238(ra) # 80001984 <cpuid>
    8000289e:	c901                	beqz	a0,800028ae <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a6:	14479073          	csrw	sip,a5
    return 2;
    800028aa:	4509                	li	a0,2
    800028ac:	b761                	j	80002834 <devintr+0x1e>
      clockintr();
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	f22080e7          	jalr	-222(ra) # 800027d0 <clockintr>
    800028b6:	b7ed                	j	800028a0 <devintr+0x8a>

00000000800028b8 <usertrap>:
{
    800028b8:	1101                	addi	sp,sp,-32
    800028ba:	ec06                	sd	ra,24(sp)
    800028bc:	e822                	sd	s0,16(sp)
    800028be:	e426                	sd	s1,8(sp)
    800028c0:	e04a                	sd	s2,0(sp)
    800028c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028c8:	1007f793          	andi	a5,a5,256
    800028cc:	e3ad                	bnez	a5,8000292e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ce:	00003797          	auipc	a5,0x3
    800028d2:	32278793          	addi	a5,a5,802 # 80005bf0 <kernelvec>
    800028d6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	0d6080e7          	jalr	214(ra) # 800019b0 <myproc>
    800028e2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e6:	14102773          	csrr	a4,sepc
    800028ea:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ec:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f0:	47a1                	li	a5,8
    800028f2:	04f71c63          	bne	a4,a5,8000294a <usertrap+0x92>
    if(p->killed)
    800028f6:	551c                	lw	a5,40(a0)
    800028f8:	e3b9                	bnez	a5,8000293e <usertrap+0x86>
    p->trapframe->epc += 4;
    800028fa:	6cb8                	ld	a4,88(s1)
    800028fc:	6f1c                	ld	a5,24(a4)
    800028fe:	0791                	addi	a5,a5,4
    80002900:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002902:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002906:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290a:	10079073          	csrw	sstatus,a5
    syscall();
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	2e0080e7          	jalr	736(ra) # 80002bee <syscall>
  if(p->killed)
    80002916:	549c                	lw	a5,40(s1)
    80002918:	ebc1                	bnez	a5,800029a8 <usertrap+0xf0>
  usertrapret();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	e18080e7          	jalr	-488(ra) # 80002732 <usertrapret>
}
    80002922:	60e2                	ld	ra,24(sp)
    80002924:	6442                	ld	s0,16(sp)
    80002926:	64a2                	ld	s1,8(sp)
    80002928:	6902                	ld	s2,0(sp)
    8000292a:	6105                	addi	sp,sp,32
    8000292c:	8082                	ret
    panic("usertrap: not from user mode");
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	9ea50513          	addi	a0,a0,-1558 # 80008318 <states.1717+0x58>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c08080e7          	jalr	-1016(ra) # 8000053e <panic>
      exit(-1);
    8000293e:	557d                	li	a0,-1
    80002940:	00000097          	auipc	ra,0x0
    80002944:	9e8080e7          	jalr	-1560(ra) # 80002328 <exit>
    80002948:	bf4d                	j	800028fa <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	ecc080e7          	jalr	-308(ra) # 80002816 <devintr>
    80002952:	892a                	mv	s2,a0
    80002954:	c501                	beqz	a0,8000295c <usertrap+0xa4>
  if(p->killed)
    80002956:	549c                	lw	a5,40(s1)
    80002958:	c3a1                	beqz	a5,80002998 <usertrap+0xe0>
    8000295a:	a815                	j	8000298e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002960:	5890                	lw	a2,48(s1)
    80002962:	00006517          	auipc	a0,0x6
    80002966:	9d650513          	addi	a0,a0,-1578 # 80008338 <states.1717+0x78>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c1e080e7          	jalr	-994(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002972:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002976:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	9ee50513          	addi	a0,a0,-1554 # 80008368 <states.1717+0xa8>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c06080e7          	jalr	-1018(ra) # 80000588 <printf>
    p->killed = 1;
    8000298a:	4785                	li	a5,1
    8000298c:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000298e:	557d                	li	a0,-1
    80002990:	00000097          	auipc	ra,0x0
    80002994:	998080e7          	jalr	-1640(ra) # 80002328 <exit>
  if(which_dev == 2)
    80002998:	4789                	li	a5,2
    8000299a:	f8f910e3          	bne	s2,a5,8000291a <usertrap+0x62>
    yield();
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	6f2080e7          	jalr	1778(ra) # 80002090 <yield>
    800029a6:	bf95                	j	8000291a <usertrap+0x62>
  int which_dev = 0;
    800029a8:	4901                	li	s2,0
    800029aa:	b7d5                	j	8000298e <usertrap+0xd6>

00000000800029ac <kerneltrap>:
{
    800029ac:	7179                	addi	sp,sp,-48
    800029ae:	f406                	sd	ra,40(sp)
    800029b0:	f022                	sd	s0,32(sp)
    800029b2:	ec26                	sd	s1,24(sp)
    800029b4:	e84a                	sd	s2,16(sp)
    800029b6:	e44e                	sd	s3,8(sp)
    800029b8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ba:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029be:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029c6:	1004f793          	andi	a5,s1,256
    800029ca:	cb85                	beqz	a5,800029fa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029cc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d2:	ef85                	bnez	a5,80002a0a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	e42080e7          	jalr	-446(ra) # 80002816 <devintr>
    800029dc:	cd1d                	beqz	a0,80002a1a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029de:	4789                	li	a5,2
    800029e0:	06f50a63          	beq	a0,a5,80002a54 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e8:	10049073          	csrw	sstatus,s1
}
    800029ec:	70a2                	ld	ra,40(sp)
    800029ee:	7402                	ld	s0,32(sp)
    800029f0:	64e2                	ld	s1,24(sp)
    800029f2:	6942                	ld	s2,16(sp)
    800029f4:	69a2                	ld	s3,8(sp)
    800029f6:	6145                	addi	sp,sp,48
    800029f8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	98e50513          	addi	a0,a0,-1650 # 80008388 <states.1717+0xc8>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9a650513          	addi	a0,a0,-1626 # 800083b0 <states.1717+0xf0>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a1a:	85ce                	mv	a1,s3
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	9b450513          	addi	a0,a0,-1612 # 800083d0 <states.1717+0x110>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b64080e7          	jalr	-1180(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a30:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	9ac50513          	addi	a0,a0,-1620 # 800083e0 <states.1717+0x120>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b4c080e7          	jalr	-1204(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	9b450513          	addi	a0,a0,-1612 # 800083f8 <states.1717+0x138>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f5c080e7          	jalr	-164(ra) # 800019b0 <myproc>
    80002a5c:	d541                	beqz	a0,800029e4 <kerneltrap+0x38>
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	f52080e7          	jalr	-174(ra) # 800019b0 <myproc>
    80002a66:	4d18                	lw	a4,24(a0)
    80002a68:	4791                	li	a5,4
    80002a6a:	f6f71de3          	bne	a4,a5,800029e4 <kerneltrap+0x38>
    yield();
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	622080e7          	jalr	1570(ra) # 80002090 <yield>
    80002a76:	b7bd                	j	800029e4 <kerneltrap+0x38>

0000000080002a78 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a78:	1101                	addi	sp,sp,-32
    80002a7a:	ec06                	sd	ra,24(sp)
    80002a7c:	e822                	sd	s0,16(sp)
    80002a7e:	e426                	sd	s1,8(sp)
    80002a80:	1000                	addi	s0,sp,32
    80002a82:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	f2c080e7          	jalr	-212(ra) # 800019b0 <myproc>
  switch (n) {
    80002a8c:	4795                	li	a5,5
    80002a8e:	0497e163          	bltu	a5,s1,80002ad0 <argraw+0x58>
    80002a92:	048a                	slli	s1,s1,0x2
    80002a94:	00006717          	auipc	a4,0x6
    80002a98:	99c70713          	addi	a4,a4,-1636 # 80008430 <states.1717+0x170>
    80002a9c:	94ba                	add	s1,s1,a4
    80002a9e:	409c                	lw	a5,0(s1)
    80002aa0:	97ba                	add	a5,a5,a4
    80002aa2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
    return p->trapframe->a1;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	7fa8                	ld	a0,120(a5)
    80002ab6:	bfcd                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a2;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	63c8                	ld	a0,128(a5)
    80002abc:	b7f5                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a3;
    80002abe:	6d3c                	ld	a5,88(a0)
    80002ac0:	67c8                	ld	a0,136(a5)
    80002ac2:	b7dd                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a4;
    80002ac4:	6d3c                	ld	a5,88(a0)
    80002ac6:	6bc8                	ld	a0,144(a5)
    80002ac8:	b7c5                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a5;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	6fc8                	ld	a0,152(a5)
    80002ace:	bfe9                	j	80002aa8 <argraw+0x30>
  panic("argraw");
    80002ad0:	00006517          	auipc	a0,0x6
    80002ad4:	93850513          	addi	a0,a0,-1736 # 80008408 <states.1717+0x148>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>

0000000080002ae0 <fetchaddr>:
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84aa                	mv	s1,a0
    80002aee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	ec0080e7          	jalr	-320(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002af8:	653c                	ld	a5,72(a0)
    80002afa:	02f4f863          	bgeu	s1,a5,80002b2a <fetchaddr+0x4a>
    80002afe:	00848713          	addi	a4,s1,8
    80002b02:	02e7e663          	bltu	a5,a4,80002b2e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b06:	46a1                	li	a3,8
    80002b08:	8626                	mv	a2,s1
    80002b0a:	85ca                	mv	a1,s2
    80002b0c:	6928                	ld	a0,80(a0)
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	bf0080e7          	jalr	-1040(ra) # 800016fe <copyin>
    80002b16:	00a03533          	snez	a0,a0
    80002b1a:	40a00533          	neg	a0,a0
}
    80002b1e:	60e2                	ld	ra,24(sp)
    80002b20:	6442                	ld	s0,16(sp)
    80002b22:	64a2                	ld	s1,8(sp)
    80002b24:	6902                	ld	s2,0(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret
    return -1;
    80002b2a:	557d                	li	a0,-1
    80002b2c:	bfcd                	j	80002b1e <fetchaddr+0x3e>
    80002b2e:	557d                	li	a0,-1
    80002b30:	b7fd                	j	80002b1e <fetchaddr+0x3e>

0000000080002b32 <fetchstr>:
{
    80002b32:	7179                	addi	sp,sp,-48
    80002b34:	f406                	sd	ra,40(sp)
    80002b36:	f022                	sd	s0,32(sp)
    80002b38:	ec26                	sd	s1,24(sp)
    80002b3a:	e84a                	sd	s2,16(sp)
    80002b3c:	e44e                	sd	s3,8(sp)
    80002b3e:	1800                	addi	s0,sp,48
    80002b40:	892a                	mv	s2,a0
    80002b42:	84ae                	mv	s1,a1
    80002b44:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	e6a080e7          	jalr	-406(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b4e:	86ce                	mv	a3,s3
    80002b50:	864a                	mv	a2,s2
    80002b52:	85a6                	mv	a1,s1
    80002b54:	6928                	ld	a0,80(a0)
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	c34080e7          	jalr	-972(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b5e:	00054763          	bltz	a0,80002b6c <fetchstr+0x3a>
  return strlen(buf);
    80002b62:	8526                	mv	a0,s1
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	300080e7          	jalr	768(ra) # 80000e64 <strlen>
}
    80002b6c:	70a2                	ld	ra,40(sp)
    80002b6e:	7402                	ld	s0,32(sp)
    80002b70:	64e2                	ld	s1,24(sp)
    80002b72:	6942                	ld	s2,16(sp)
    80002b74:	69a2                	ld	s3,8(sp)
    80002b76:	6145                	addi	sp,sp,48
    80002b78:	8082                	ret

0000000080002b7a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b7a:	1101                	addi	sp,sp,-32
    80002b7c:	ec06                	sd	ra,24(sp)
    80002b7e:	e822                	sd	s0,16(sp)
    80002b80:	e426                	sd	s1,8(sp)
    80002b82:	1000                	addi	s0,sp,32
    80002b84:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	ef2080e7          	jalr	-270(ra) # 80002a78 <argraw>
    80002b8e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b90:	4501                	li	a0,0
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	ed0080e7          	jalr	-304(ra) # 80002a78 <argraw>
    80002bb0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb2:	4501                	li	a0,0
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret

0000000080002bbe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	e04a                	sd	s2,0(sp)
    80002bc8:	1000                	addi	s0,sp,32
    80002bca:	84ae                	mv	s1,a1
    80002bcc:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	eaa080e7          	jalr	-342(ra) # 80002a78 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bd6:	864a                	mv	a2,s2
    80002bd8:	85a6                	mv	a1,s1
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	f58080e7          	jalr	-168(ra) # 80002b32 <fetchstr>
}
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6902                	ld	s2,0(sp)
    80002bea:	6105                	addi	sp,sp,32
    80002bec:	8082                	ret

0000000080002bee <syscall>:
[SYS_kill_system]       sys_kill_system,
};

void
syscall(void)
{
    80002bee:	1101                	addi	sp,sp,-32
    80002bf0:	ec06                	sd	ra,24(sp)
    80002bf2:	e822                	sd	s0,16(sp)
    80002bf4:	e426                	sd	s1,8(sp)
    80002bf6:	e04a                	sd	s2,0(sp)
    80002bf8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	db6080e7          	jalr	-586(ra) # 800019b0 <myproc>
    80002c02:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c04:	05853903          	ld	s2,88(a0)
    80002c08:	0a893783          	ld	a5,168(s2)
    80002c0c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c10:	37fd                	addiw	a5,a5,-1
    80002c12:	4759                	li	a4,22
    80002c14:	00f76f63          	bltu	a4,a5,80002c32 <syscall+0x44>
    80002c18:	00369713          	slli	a4,a3,0x3
    80002c1c:	00006797          	auipc	a5,0x6
    80002c20:	82c78793          	addi	a5,a5,-2004 # 80008448 <syscalls>
    80002c24:	97ba                	add	a5,a5,a4
    80002c26:	639c                	ld	a5,0(a5)
    80002c28:	c789                	beqz	a5,80002c32 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c2a:	9782                	jalr	a5
    80002c2c:	06a93823          	sd	a0,112(s2)
    80002c30:	a839                	j	80002c4e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c32:	15848613          	addi	a2,s1,344
    80002c36:	588c                	lw	a1,48(s1)
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	7d850513          	addi	a0,a0,2008 # 80008410 <states.1717+0x150>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	948080e7          	jalr	-1720(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c48:	6cbc                	ld	a5,88(s1)
    80002c4a:	577d                	li	a4,-1
    80002c4c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret

0000000080002c5a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c62:	fec40593          	addi	a1,s0,-20
    80002c66:	4501                	li	a0,0
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	f12080e7          	jalr	-238(ra) # 80002b7a <argint>
    return -1;
    80002c70:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c72:	00054963          	bltz	a0,80002c84 <sys_exit+0x2a>
  exit(n);
    80002c76:	fec42503          	lw	a0,-20(s0)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	6ae080e7          	jalr	1710(ra) # 80002328 <exit>
  return 0;  // not reached
    80002c82:	4781                	li	a5,0
}
    80002c84:	853e                	mv	a0,a5
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	6105                	addi	sp,sp,32
    80002c8c:	8082                	ret

0000000080002c8e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c8e:	1141                	addi	sp,sp,-16
    80002c90:	e406                	sd	ra,8(sp)
    80002c92:	e022                	sd	s0,0(sp)
    80002c94:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	d1a080e7          	jalr	-742(ra) # 800019b0 <myproc>
}
    80002c9e:	5908                	lw	a0,48(a0)
    80002ca0:	60a2                	ld	ra,8(sp)
    80002ca2:	6402                	ld	s0,0(sp)
    80002ca4:	0141                	addi	sp,sp,16
    80002ca6:	8082                	ret

0000000080002ca8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca8:	1141                	addi	sp,sp,-16
    80002caa:	e406                	sd	ra,8(sp)
    80002cac:	e022                	sd	s0,0(sp)
    80002cae:	0800                	addi	s0,sp,16
  return fork();
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	0ce080e7          	jalr	206(ra) # 80001d7e <fork>
}
    80002cb8:	60a2                	ld	ra,8(sp)
    80002cba:	6402                	ld	s0,0(sp)
    80002cbc:	0141                	addi	sp,sp,16
    80002cbe:	8082                	ret

0000000080002cc0 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cc8:	fe840593          	addi	a1,s0,-24
    80002ccc:	4501                	li	a0,0
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	ece080e7          	jalr	-306(ra) # 80002b9c <argaddr>
    80002cd6:	87aa                	mv	a5,a0
    return -1;
    80002cd8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cda:	0007c863          	bltz	a5,80002cea <sys_wait+0x2a>
  return wait(p);
    80002cde:	fe843503          	ld	a0,-24(s0)
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	44e080e7          	jalr	1102(ra) # 80002130 <wait>
}
    80002cea:	60e2                	ld	ra,24(sp)
    80002cec:	6442                	ld	s0,16(sp)
    80002cee:	6105                	addi	sp,sp,32
    80002cf0:	8082                	ret

0000000080002cf2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf2:	7179                	addi	sp,sp,-48
    80002cf4:	f406                	sd	ra,40(sp)
    80002cf6:	f022                	sd	s0,32(sp)
    80002cf8:	ec26                	sd	s1,24(sp)
    80002cfa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cfc:	fdc40593          	addi	a1,s0,-36
    80002d00:	4501                	li	a0,0
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	e78080e7          	jalr	-392(ra) # 80002b7a <argint>
    80002d0a:	87aa                	mv	a5,a0
    return -1;
    80002d0c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d0e:	0207c063          	bltz	a5,80002d2e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	c9e080e7          	jalr	-866(ra) # 800019b0 <myproc>
    80002d1a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d1c:	fdc42503          	lw	a0,-36(s0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	fea080e7          	jalr	-22(ra) # 80001d0a <growproc>
    80002d28:	00054863          	bltz	a0,80002d38 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d2c:	8526                	mv	a0,s1
}
    80002d2e:	70a2                	ld	ra,40(sp)
    80002d30:	7402                	ld	s0,32(sp)
    80002d32:	64e2                	ld	s1,24(sp)
    80002d34:	6145                	addi	sp,sp,48
    80002d36:	8082                	ret
    return -1;
    80002d38:	557d                	li	a0,-1
    80002d3a:	bfd5                	j	80002d2e <sys_sbrk+0x3c>

0000000080002d3c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d3c:	7139                	addi	sp,sp,-64
    80002d3e:	fc06                	sd	ra,56(sp)
    80002d40:	f822                	sd	s0,48(sp)
    80002d42:	f426                	sd	s1,40(sp)
    80002d44:	f04a                	sd	s2,32(sp)
    80002d46:	ec4e                	sd	s3,24(sp)
    80002d48:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d4a:	fcc40593          	addi	a1,s0,-52
    80002d4e:	4501                	li	a0,0
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	e2a080e7          	jalr	-470(ra) # 80002b7a <argint>
    return -1;
    80002d58:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5a:	06054563          	bltz	a0,80002dc4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d5e:	00014517          	auipc	a0,0x14
    80002d62:	37250513          	addi	a0,a0,882 # 800170d0 <tickslock>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	e7e080e7          	jalr	-386(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d6e:	00006917          	auipc	s2,0x6
    80002d72:	2c692903          	lw	s2,710(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80002d76:	fcc42783          	lw	a5,-52(s0)
    80002d7a:	cf85                	beqz	a5,80002db2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d7c:	00014997          	auipc	s3,0x14
    80002d80:	35498993          	addi	s3,s3,852 # 800170d0 <tickslock>
    80002d84:	00006497          	auipc	s1,0x6
    80002d88:	2b048493          	addi	s1,s1,688 # 80009034 <ticks>
    if(myproc()->killed){
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	c24080e7          	jalr	-988(ra) # 800019b0 <myproc>
    80002d94:	551c                	lw	a5,40(a0)
    80002d96:	ef9d                	bnez	a5,80002dd4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d98:	85ce                	mv	a1,s3
    80002d9a:	8526                	mv	a0,s1
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	330080e7          	jalr	816(ra) # 800020cc <sleep>
  while(ticks - ticks0 < n){
    80002da4:	409c                	lw	a5,0(s1)
    80002da6:	412787bb          	subw	a5,a5,s2
    80002daa:	fcc42703          	lw	a4,-52(s0)
    80002dae:	fce7efe3          	bltu	a5,a4,80002d8c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db2:	00014517          	auipc	a0,0x14
    80002db6:	31e50513          	addi	a0,a0,798 # 800170d0 <tickslock>
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	ede080e7          	jalr	-290(ra) # 80000c98 <release>
  return 0;
    80002dc2:	4781                	li	a5,0
}
    80002dc4:	853e                	mv	a0,a5
    80002dc6:	70e2                	ld	ra,56(sp)
    80002dc8:	7442                	ld	s0,48(sp)
    80002dca:	74a2                	ld	s1,40(sp)
    80002dcc:	7902                	ld	s2,32(sp)
    80002dce:	69e2                	ld	s3,24(sp)
    80002dd0:	6121                	addi	sp,sp,64
    80002dd2:	8082                	ret
      release(&tickslock);
    80002dd4:	00014517          	auipc	a0,0x14
    80002dd8:	2fc50513          	addi	a0,a0,764 # 800170d0 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	ebc080e7          	jalr	-324(ra) # 80000c98 <release>
      return -1;
    80002de4:	57fd                	li	a5,-1
    80002de6:	bff9                	j	80002dc4 <sys_sleep+0x88>

0000000080002de8 <sys_kill>:

uint64
sys_kill(void)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df0:	fec40593          	addi	a1,s0,-20
    80002df4:	4501                	li	a0,0
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	d84080e7          	jalr	-636(ra) # 80002b7a <argint>
    80002dfe:	87aa                	mv	a5,a0
    return -1;
    80002e00:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e02:	0007c863          	bltz	a5,80002e12 <sys_kill+0x2a>
  return kill(pid);
    80002e06:	fec42503          	lw	a0,-20(s0)
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	5f4080e7          	jalr	1524(ra) # 800023fe <kill>
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e24:	00014517          	auipc	a0,0x14
    80002e28:	2ac50513          	addi	a0,a0,684 # 800170d0 <tickslock>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	db8080e7          	jalr	-584(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e34:	00006497          	auipc	s1,0x6
    80002e38:	2004a483          	lw	s1,512(s1) # 80009034 <ticks>
  release(&tickslock);
    80002e3c:	00014517          	auipc	a0,0x14
    80002e40:	29450513          	addi	a0,a0,660 # 800170d0 <tickslock>
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	e54080e7          	jalr	-428(ra) # 80000c98 <release>
  return xticks;
}
    80002e4c:	02049513          	slli	a0,s1,0x20
    80002e50:	9101                	srli	a0,a0,0x20
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	64a2                	ld	s1,8(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret

0000000080002e5c <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002e5c:	1101                	addi	sp,sp,-32
    80002e5e:	ec06                	sd	ra,24(sp)
    80002e60:	e822                	sd	s0,16(sp)
    80002e62:	1000                	addi	s0,sp,32
  int ticks0;
  if(argint(0, &ticks0) < 0)
    80002e64:	fec40593          	addi	a1,s0,-20
    80002e68:	4501                	li	a0,0
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	d10080e7          	jalr	-752(ra) # 80002b7a <argint>
    return -1;
    80002e72:	57fd                	li	a5,-1
  if(argint(0, &ticks0) < 0)
    80002e74:	00054963          	bltz	a0,80002e86 <sys_pause_system+0x2a>
  pause_system(ticks0);
    80002e78:	fec42503          	lw	a0,-20(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	74e080e7          	jalr	1870(ra) # 800025ca <pause_system>
  return 0;
    80002e84:	4781                	li	a5,0
}
    80002e86:	853e                	mv	a0,a5
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002e90:	1141                	addi	sp,sp,-16
    80002e92:	e406                	sd	ra,8(sp)
    80002e94:	e022                	sd	s0,0(sp)
    80002e96:	0800                	addi	s0,sp,16
  kill_system();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	790080e7          	jalr	1936(ra) # 80002628 <kill_system>
  return 0;
    80002ea0:	4501                	li	a0,0
    80002ea2:	60a2                	ld	ra,8(sp)
    80002ea4:	6402                	ld	s0,0(sp)
    80002ea6:	0141                	addi	sp,sp,16
    80002ea8:	8082                	ret

0000000080002eaa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	e052                	sd	s4,0(sp)
    80002eb8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eba:	00005597          	auipc	a1,0x5
    80002ebe:	64e58593          	addi	a1,a1,1614 # 80008508 <syscalls+0xc0>
    80002ec2:	00014517          	auipc	a0,0x14
    80002ec6:	22650513          	addi	a0,a0,550 # 800170e8 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	c8a080e7          	jalr	-886(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed2:	0001c797          	auipc	a5,0x1c
    80002ed6:	21678793          	addi	a5,a5,534 # 8001f0e8 <bcache+0x8000>
    80002eda:	0001c717          	auipc	a4,0x1c
    80002ede:	47670713          	addi	a4,a4,1142 # 8001f350 <bcache+0x8268>
    80002ee2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eea:	00014497          	auipc	s1,0x14
    80002eee:	21648493          	addi	s1,s1,534 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef6:	00005a17          	auipc	s4,0x5
    80002efa:	61aa0a13          	addi	s4,s4,1562 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002efe:	2b893783          	ld	a5,696(s2)
    80002f02:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f04:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f08:	85d2                	mv	a1,s4
    80002f0a:	01048513          	addi	a0,s1,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	4bc080e7          	jalr	1212(ra) # 800043ca <initsleeplock>
    bcache.head.next->prev = b;
    80002f16:	2b893783          	ld	a5,696(s2)
    80002f1a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	45848493          	addi	s1,s1,1112
    80002f24:	fd349de3          	bne	s1,s3,80002efe <binit+0x54>
  }
}
    80002f28:	70a2                	ld	ra,40(sp)
    80002f2a:	7402                	ld	s0,32(sp)
    80002f2c:	64e2                	ld	s1,24(sp)
    80002f2e:	6942                	ld	s2,16(sp)
    80002f30:	69a2                	ld	s3,8(sp)
    80002f32:	6a02                	ld	s4,0(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret

0000000080002f38 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	1800                	addi	s0,sp,48
    80002f46:	89aa                	mv	s3,a0
    80002f48:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f4a:	00014517          	auipc	a0,0x14
    80002f4e:	19e50513          	addi	a0,a0,414 # 800170e8 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5a:	0001c497          	auipc	s1,0x1c
    80002f5e:	4464b483          	ld	s1,1094(s1) # 8001f3a0 <bcache+0x82b8>
    80002f62:	0001c797          	auipc	a5,0x1c
    80002f66:	3ee78793          	addi	a5,a5,1006 # 8001f350 <bcache+0x8268>
    80002f6a:	02f48f63          	beq	s1,a5,80002fa8 <bread+0x70>
    80002f6e:	873e                	mv	a4,a5
    80002f70:	a021                	j	80002f78 <bread+0x40>
    80002f72:	68a4                	ld	s1,80(s1)
    80002f74:	02e48a63          	beq	s1,a4,80002fa8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f78:	449c                	lw	a5,8(s1)
    80002f7a:	ff379ce3          	bne	a5,s3,80002f72 <bread+0x3a>
    80002f7e:	44dc                	lw	a5,12(s1)
    80002f80:	ff2799e3          	bne	a5,s2,80002f72 <bread+0x3a>
      b->refcnt++;
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	2785                	addiw	a5,a5,1
    80002f88:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8a:	00014517          	auipc	a0,0x14
    80002f8e:	15e50513          	addi	a0,a0,350 # 800170e8 <bcache>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f9a:	01048513          	addi	a0,s1,16
    80002f9e:	00001097          	auipc	ra,0x1
    80002fa2:	466080e7          	jalr	1126(ra) # 80004404 <acquiresleep>
      return b;
    80002fa6:	a8b9                	j	80003004 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	0001c497          	auipc	s1,0x1c
    80002fac:	3f04b483          	ld	s1,1008(s1) # 8001f398 <bcache+0x82b0>
    80002fb0:	0001c797          	auipc	a5,0x1c
    80002fb4:	3a078793          	addi	a5,a5,928 # 8001f350 <bcache+0x8268>
    80002fb8:	00f48863          	beq	s1,a5,80002fc8 <bread+0x90>
    80002fbc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fbe:	40bc                	lw	a5,64(s1)
    80002fc0:	cf81                	beqz	a5,80002fd8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc2:	64a4                	ld	s1,72(s1)
    80002fc4:	fee49de3          	bne	s1,a4,80002fbe <bread+0x86>
  panic("bget: no buffers");
    80002fc8:	00005517          	auipc	a0,0x5
    80002fcc:	55050513          	addi	a0,a0,1360 # 80008518 <syscalls+0xd0>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	56e080e7          	jalr	1390(ra) # 8000053e <panic>
      b->dev = dev;
    80002fd8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fdc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fe0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe4:	4785                	li	a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	10050513          	addi	a0,a0,256 # 800170e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	ca8080e7          	jalr	-856(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	408080e7          	jalr	1032(ra) # 80004404 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003004:	409c                	lw	a5,0(s1)
    80003006:	cb89                	beqz	a5,80003018 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003008:	8526                	mv	a0,s1
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	69a2                	ld	s3,8(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret
    virtio_disk_rw(b, 0);
    80003018:	4581                	li	a1,0
    8000301a:	8526                	mv	a0,s1
    8000301c:	00003097          	auipc	ra,0x3
    80003020:	f0a080e7          	jalr	-246(ra) # 80005f26 <virtio_disk_rw>
    b->valid = 1;
    80003024:	4785                	li	a5,1
    80003026:	c09c                	sw	a5,0(s1)
  return b;
    80003028:	b7c5                	j	80003008 <bread+0xd0>

000000008000302a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003036:	0541                	addi	a0,a0,16
    80003038:	00001097          	auipc	ra,0x1
    8000303c:	466080e7          	jalr	1126(ra) # 8000449e <holdingsleep>
    80003040:	cd01                	beqz	a0,80003058 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003042:	4585                	li	a1,1
    80003044:	8526                	mv	a0,s1
    80003046:	00003097          	auipc	ra,0x3
    8000304a:	ee0080e7          	jalr	-288(ra) # 80005f26 <virtio_disk_rw>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret
    panic("bwrite");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	4d850513          	addi	a0,a0,1240 # 80008530 <syscalls+0xe8>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>

0000000080003068 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	e04a                	sd	s2,0(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003076:	01050913          	addi	s2,a0,16
    8000307a:	854a                	mv	a0,s2
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	422080e7          	jalr	1058(ra) # 8000449e <holdingsleep>
    80003084:	c92d                	beqz	a0,800030f6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003086:	854a                	mv	a0,s2
    80003088:	00001097          	auipc	ra,0x1
    8000308c:	3d2080e7          	jalr	978(ra) # 8000445a <releasesleep>

  acquire(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	05850513          	addi	a0,a0,88 # 800170e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	b4c080e7          	jalr	-1204(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030a0:	40bc                	lw	a5,64(s1)
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	0007871b          	sext.w	a4,a5
    800030a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030aa:	eb05                	bnez	a4,800030da <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ac:	68bc                	ld	a5,80(s1)
    800030ae:	64b8                	ld	a4,72(s1)
    800030b0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b2:	64bc                	ld	a5,72(s1)
    800030b4:	68b8                	ld	a4,80(s1)
    800030b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b8:	0001c797          	auipc	a5,0x1c
    800030bc:	03078793          	addi	a5,a5,48 # 8001f0e8 <bcache+0x8000>
    800030c0:	2b87b703          	ld	a4,696(a5)
    800030c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c6:	0001c717          	auipc	a4,0x1c
    800030ca:	28a70713          	addi	a4,a4,650 # 8001f350 <bcache+0x8268>
    800030ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d0:	2b87b703          	ld	a4,696(a5)
    800030d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030da:	00014517          	auipc	a0,0x14
    800030de:	00e50513          	addi	a0,a0,14 # 800170e8 <bcache>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	bb6080e7          	jalr	-1098(ra) # 80000c98 <release>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6902                	ld	s2,0(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret
    panic("brelse");
    800030f6:	00005517          	auipc	a0,0x5
    800030fa:	44250513          	addi	a0,a0,1090 # 80008538 <syscalls+0xf0>
    800030fe:	ffffd097          	auipc	ra,0xffffd
    80003102:	440080e7          	jalr	1088(ra) # 8000053e <panic>

0000000080003106 <bpin>:

void
bpin(struct buf *b) {
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	fd650513          	addi	a0,a0,-42 # 800170e8 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	aca080e7          	jalr	-1334(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	2785                	addiw	a5,a5,1
    80003126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003128:	00014517          	auipc	a0,0x14
    8000312c:	fc050513          	addi	a0,a0,-64 # 800170e8 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <bunpin>:

void
bunpin(struct buf *b) {
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	f9a50513          	addi	a0,a0,-102 # 800170e8 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	a8e080e7          	jalr	-1394(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000315e:	40bc                	lw	a5,64(s1)
    80003160:	37fd                	addiw	a5,a5,-1
    80003162:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003164:	00014517          	auipc	a0,0x14
    80003168:	f8450513          	addi	a0,a0,-124 # 800170e8 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	b2c080e7          	jalr	-1236(ra) # 80000c98 <release>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	e04a                	sd	s2,0(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000318c:	00d5d59b          	srliw	a1,a1,0xd
    80003190:	0001c797          	auipc	a5,0x1c
    80003194:	6347a783          	lw	a5,1588(a5) # 8001f7c4 <sb+0x1c>
    80003198:	9dbd                	addw	a1,a1,a5
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	d9e080e7          	jalr	-610(ra) # 80002f38 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a2:	0074f713          	andi	a4,s1,7
    800031a6:	4785                	li	a5,1
    800031a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ac:	14ce                	slli	s1,s1,0x33
    800031ae:	90d9                	srli	s1,s1,0x36
    800031b0:	00950733          	add	a4,a0,s1
    800031b4:	05874703          	lbu	a4,88(a4)
    800031b8:	00e7f6b3          	and	a3,a5,a4
    800031bc:	c69d                	beqz	a3,800031ea <bfree+0x6c>
    800031be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c0:	94aa                	add	s1,s1,a0
    800031c2:	fff7c793          	not	a5,a5
    800031c6:	8ff9                	and	a5,a5,a4
    800031c8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	118080e7          	jalr	280(ra) # 800042e4 <log_write>
  brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	e92080e7          	jalr	-366(ra) # 80003068 <brelse>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6902                	ld	s2,0(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret
    panic("freeing free block");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	35650513          	addi	a0,a0,854 # 80008540 <syscalls+0xf8>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>

00000000800031fa <balloc>:
{
    800031fa:	711d                	addi	sp,sp,-96
    800031fc:	ec86                	sd	ra,88(sp)
    800031fe:	e8a2                	sd	s0,80(sp)
    80003200:	e4a6                	sd	s1,72(sp)
    80003202:	e0ca                	sd	s2,64(sp)
    80003204:	fc4e                	sd	s3,56(sp)
    80003206:	f852                	sd	s4,48(sp)
    80003208:	f456                	sd	s5,40(sp)
    8000320a:	f05a                	sd	s6,32(sp)
    8000320c:	ec5e                	sd	s7,24(sp)
    8000320e:	e862                	sd	s8,16(sp)
    80003210:	e466                	sd	s9,8(sp)
    80003212:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003214:	0001c797          	auipc	a5,0x1c
    80003218:	5987a783          	lw	a5,1432(a5) # 8001f7ac <sb+0x4>
    8000321c:	cbd1                	beqz	a5,800032b0 <balloc+0xb6>
    8000321e:	8baa                	mv	s7,a0
    80003220:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003222:	0001cb17          	auipc	s6,0x1c
    80003226:	586b0b13          	addi	s6,s6,1414 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000322c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003230:	6c89                	lui	s9,0x2
    80003232:	a831                	j	8000324e <balloc+0x54>
    brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	e32080e7          	jalr	-462(ra) # 80003068 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000323e:	015c87bb          	addw	a5,s9,s5
    80003242:	00078a9b          	sext.w	s5,a5
    80003246:	004b2703          	lw	a4,4(s6)
    8000324a:	06eaf363          	bgeu	s5,a4,800032b0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000324e:	41fad79b          	sraiw	a5,s5,0x1f
    80003252:	0137d79b          	srliw	a5,a5,0x13
    80003256:	015787bb          	addw	a5,a5,s5
    8000325a:	40d7d79b          	sraiw	a5,a5,0xd
    8000325e:	01cb2583          	lw	a1,28(s6)
    80003262:	9dbd                	addw	a1,a1,a5
    80003264:	855e                	mv	a0,s7
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	cd2080e7          	jalr	-814(ra) # 80002f38 <bread>
    8000326e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	004b2503          	lw	a0,4(s6)
    80003274:	000a849b          	sext.w	s1,s5
    80003278:	8662                	mv	a2,s8
    8000327a:	faa4fde3          	bgeu	s1,a0,80003234 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000327e:	41f6579b          	sraiw	a5,a2,0x1f
    80003282:	01d7d69b          	srliw	a3,a5,0x1d
    80003286:	00c6873b          	addw	a4,a3,a2
    8000328a:	00777793          	andi	a5,a4,7
    8000328e:	9f95                	subw	a5,a5,a3
    80003290:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003294:	4037571b          	sraiw	a4,a4,0x3
    80003298:	00e906b3          	add	a3,s2,a4
    8000329c:	0586c683          	lbu	a3,88(a3)
    800032a0:	00d7f5b3          	and	a1,a5,a3
    800032a4:	cd91                	beqz	a1,800032c0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	2605                	addiw	a2,a2,1
    800032a8:	2485                	addiw	s1,s1,1
    800032aa:	fd4618e3          	bne	a2,s4,8000327a <balloc+0x80>
    800032ae:	b759                	j	80003234 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	2a850513          	addi	a0,a0,680 # 80008558 <syscalls+0x110>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	286080e7          	jalr	646(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032c0:	974a                	add	a4,a4,s2
    800032c2:	8fd5                	or	a5,a5,a3
    800032c4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	01a080e7          	jalr	26(ra) # 800042e4 <log_write>
        brelse(bp);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	d94080e7          	jalr	-620(ra) # 80003068 <brelse>
  bp = bread(dev, bno);
    800032dc:	85a6                	mv	a1,s1
    800032de:	855e                	mv	a0,s7
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	c58080e7          	jalr	-936(ra) # 80002f38 <bread>
    800032e8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ea:	40000613          	li	a2,1024
    800032ee:	4581                	li	a1,0
    800032f0:	05850513          	addi	a0,a0,88
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	9ec080e7          	jalr	-1556(ra) # 80000ce0 <memset>
  log_write(bp);
    800032fc:	854a                	mv	a0,s2
    800032fe:	00001097          	auipc	ra,0x1
    80003302:	fe6080e7          	jalr	-26(ra) # 800042e4 <log_write>
  brelse(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d60080e7          	jalr	-672(ra) # 80003068 <brelse>
}
    80003310:	8526                	mv	a0,s1
    80003312:	60e6                	ld	ra,88(sp)
    80003314:	6446                	ld	s0,80(sp)
    80003316:	64a6                	ld	s1,72(sp)
    80003318:	6906                	ld	s2,64(sp)
    8000331a:	79e2                	ld	s3,56(sp)
    8000331c:	7a42                	ld	s4,48(sp)
    8000331e:	7aa2                	ld	s5,40(sp)
    80003320:	7b02                	ld	s6,32(sp)
    80003322:	6be2                	ld	s7,24(sp)
    80003324:	6c42                	ld	s8,16(sp)
    80003326:	6ca2                	ld	s9,8(sp)
    80003328:	6125                	addi	sp,sp,96
    8000332a:	8082                	ret

000000008000332c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332c:	7179                	addi	sp,sp,-48
    8000332e:	f406                	sd	ra,40(sp)
    80003330:	f022                	sd	s0,32(sp)
    80003332:	ec26                	sd	s1,24(sp)
    80003334:	e84a                	sd	s2,16(sp)
    80003336:	e44e                	sd	s3,8(sp)
    80003338:	e052                	sd	s4,0(sp)
    8000333a:	1800                	addi	s0,sp,48
    8000333c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333e:	47ad                	li	a5,11
    80003340:	04b7fe63          	bgeu	a5,a1,8000339c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003344:	ff45849b          	addiw	s1,a1,-12
    80003348:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000334c:	0ff00793          	li	a5,255
    80003350:	0ae7e363          	bltu	a5,a4,800033f6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003354:	08052583          	lw	a1,128(a0)
    80003358:	c5ad                	beqz	a1,800033c2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000335a:	00092503          	lw	a0,0(s2)
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	bda080e7          	jalr	-1062(ra) # 80002f38 <bread>
    80003366:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003368:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000336c:	02049593          	slli	a1,s1,0x20
    80003370:	9181                	srli	a1,a1,0x20
    80003372:	058a                	slli	a1,a1,0x2
    80003374:	00b784b3          	add	s1,a5,a1
    80003378:	0004a983          	lw	s3,0(s1)
    8000337c:	04098d63          	beqz	s3,800033d6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003380:	8552                	mv	a0,s4
    80003382:	00000097          	auipc	ra,0x0
    80003386:	ce6080e7          	jalr	-794(ra) # 80003068 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000338a:	854e                	mv	a0,s3
    8000338c:	70a2                	ld	ra,40(sp)
    8000338e:	7402                	ld	s0,32(sp)
    80003390:	64e2                	ld	s1,24(sp)
    80003392:	6942                	ld	s2,16(sp)
    80003394:	69a2                	ld	s3,8(sp)
    80003396:	6a02                	ld	s4,0(sp)
    80003398:	6145                	addi	sp,sp,48
    8000339a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000339c:	02059493          	slli	s1,a1,0x20
    800033a0:	9081                	srli	s1,s1,0x20
    800033a2:	048a                	slli	s1,s1,0x2
    800033a4:	94aa                	add	s1,s1,a0
    800033a6:	0504a983          	lw	s3,80(s1)
    800033aa:	fe0990e3          	bnez	s3,8000338a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ae:	4108                	lw	a0,0(a0)
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e4a080e7          	jalr	-438(ra) # 800031fa <balloc>
    800033b8:	0005099b          	sext.w	s3,a0
    800033bc:	0534a823          	sw	s3,80(s1)
    800033c0:	b7e9                	j	8000338a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c2:	4108                	lw	a0,0(a0)
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	e36080e7          	jalr	-458(ra) # 800031fa <balloc>
    800033cc:	0005059b          	sext.w	a1,a0
    800033d0:	08b92023          	sw	a1,128(s2)
    800033d4:	b759                	j	8000335a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033d6:	00092503          	lw	a0,0(s2)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e20080e7          	jalr	-480(ra) # 800031fa <balloc>
    800033e2:	0005099b          	sext.w	s3,a0
    800033e6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ea:	8552                	mv	a0,s4
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	ef8080e7          	jalr	-264(ra) # 800042e4 <log_write>
    800033f4:	b771                	j	80003380 <bmap+0x54>
  panic("bmap: out of range");
    800033f6:	00005517          	auipc	a0,0x5
    800033fa:	17a50513          	addi	a0,a0,378 # 80008570 <syscalls+0x128>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	140080e7          	jalr	320(ra) # 8000053e <panic>

0000000080003406 <iget>:
{
    80003406:	7179                	addi	sp,sp,-48
    80003408:	f406                	sd	ra,40(sp)
    8000340a:	f022                	sd	s0,32(sp)
    8000340c:	ec26                	sd	s1,24(sp)
    8000340e:	e84a                	sd	s2,16(sp)
    80003410:	e44e                	sd	s3,8(sp)
    80003412:	e052                	sd	s4,0(sp)
    80003414:	1800                	addi	s0,sp,48
    80003416:	89aa                	mv	s3,a0
    80003418:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000341a:	0001c517          	auipc	a0,0x1c
    8000341e:	3ae50513          	addi	a0,a0,942 # 8001f7c8 <itable>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	7c2080e7          	jalr	1986(ra) # 80000be4 <acquire>
  empty = 0;
    8000342a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342c:	0001c497          	auipc	s1,0x1c
    80003430:	3b448493          	addi	s1,s1,948 # 8001f7e0 <itable+0x18>
    80003434:	0001e697          	auipc	a3,0x1e
    80003438:	e3c68693          	addi	a3,a3,-452 # 80021270 <log>
    8000343c:	a039                	j	8000344a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343e:	02090b63          	beqz	s2,80003474 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003442:	08848493          	addi	s1,s1,136
    80003446:	02d48a63          	beq	s1,a3,8000347a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000344a:	449c                	lw	a5,8(s1)
    8000344c:	fef059e3          	blez	a5,8000343e <iget+0x38>
    80003450:	4098                	lw	a4,0(s1)
    80003452:	ff3716e3          	bne	a4,s3,8000343e <iget+0x38>
    80003456:	40d8                	lw	a4,4(s1)
    80003458:	ff4713e3          	bne	a4,s4,8000343e <iget+0x38>
      ip->ref++;
    8000345c:	2785                	addiw	a5,a5,1
    8000345e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003460:	0001c517          	auipc	a0,0x1c
    80003464:	36850513          	addi	a0,a0,872 # 8001f7c8 <itable>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	830080e7          	jalr	-2000(ra) # 80000c98 <release>
      return ip;
    80003470:	8926                	mv	s2,s1
    80003472:	a03d                	j	800034a0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003474:	f7f9                	bnez	a5,80003442 <iget+0x3c>
    80003476:	8926                	mv	s2,s1
    80003478:	b7e9                	j	80003442 <iget+0x3c>
  if(empty == 0)
    8000347a:	02090c63          	beqz	s2,800034b2 <iget+0xac>
  ip->dev = dev;
    8000347e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003482:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003486:	4785                	li	a5,1
    80003488:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003490:	0001c517          	auipc	a0,0x1c
    80003494:	33850513          	addi	a0,a0,824 # 8001f7c8 <itable>
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
}
    800034a0:	854a                	mv	a0,s2
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6a02                	ld	s4,0(sp)
    800034ae:	6145                	addi	sp,sp,48
    800034b0:	8082                	ret
    panic("iget: no inodes");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	0d650513          	addi	a0,a0,214 # 80008588 <syscalls+0x140>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	084080e7          	jalr	132(ra) # 8000053e <panic>

00000000800034c2 <fsinit>:
fsinit(int dev) {
    800034c2:	7179                	addi	sp,sp,-48
    800034c4:	f406                	sd	ra,40(sp)
    800034c6:	f022                	sd	s0,32(sp)
    800034c8:	ec26                	sd	s1,24(sp)
    800034ca:	e84a                	sd	s2,16(sp)
    800034cc:	e44e                	sd	s3,8(sp)
    800034ce:	1800                	addi	s0,sp,48
    800034d0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d2:	4585                	li	a1,1
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	a64080e7          	jalr	-1436(ra) # 80002f38 <bread>
    800034dc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034de:	0001c997          	auipc	s3,0x1c
    800034e2:	2ca98993          	addi	s3,s3,714 # 8001f7a8 <sb>
    800034e6:	02000613          	li	a2,32
    800034ea:	05850593          	addi	a1,a0,88
    800034ee:	854e                	mv	a0,s3
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	850080e7          	jalr	-1968(ra) # 80000d40 <memmove>
  brelse(bp);
    800034f8:	8526                	mv	a0,s1
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	b6e080e7          	jalr	-1170(ra) # 80003068 <brelse>
  if(sb.magic != FSMAGIC)
    80003502:	0009a703          	lw	a4,0(s3)
    80003506:	102037b7          	lui	a5,0x10203
    8000350a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000350e:	02f71263          	bne	a4,a5,80003532 <fsinit+0x70>
  initlog(dev, &sb);
    80003512:	0001c597          	auipc	a1,0x1c
    80003516:	29658593          	addi	a1,a1,662 # 8001f7a8 <sb>
    8000351a:	854a                	mv	a0,s2
    8000351c:	00001097          	auipc	ra,0x1
    80003520:	b4c080e7          	jalr	-1204(ra) # 80004068 <initlog>
}
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6145                	addi	sp,sp,48
    80003530:	8082                	ret
    panic("invalid file system");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	06650513          	addi	a0,a0,102 # 80008598 <syscalls+0x150>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	004080e7          	jalr	4(ra) # 8000053e <panic>

0000000080003542 <iinit>:
{
    80003542:	7179                	addi	sp,sp,-48
    80003544:	f406                	sd	ra,40(sp)
    80003546:	f022                	sd	s0,32(sp)
    80003548:	ec26                	sd	s1,24(sp)
    8000354a:	e84a                	sd	s2,16(sp)
    8000354c:	e44e                	sd	s3,8(sp)
    8000354e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003550:	00005597          	auipc	a1,0x5
    80003554:	06058593          	addi	a1,a1,96 # 800085b0 <syscalls+0x168>
    80003558:	0001c517          	auipc	a0,0x1c
    8000355c:	27050513          	addi	a0,a0,624 # 8001f7c8 <itable>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	5f4080e7          	jalr	1524(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003568:	0001c497          	auipc	s1,0x1c
    8000356c:	28848493          	addi	s1,s1,648 # 8001f7f0 <itable+0x28>
    80003570:	0001e997          	auipc	s3,0x1e
    80003574:	d1098993          	addi	s3,s3,-752 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003578:	00005917          	auipc	s2,0x5
    8000357c:	04090913          	addi	s2,s2,64 # 800085b8 <syscalls+0x170>
    80003580:	85ca                	mv	a1,s2
    80003582:	8526                	mv	a0,s1
    80003584:	00001097          	auipc	ra,0x1
    80003588:	e46080e7          	jalr	-442(ra) # 800043ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358c:	08848493          	addi	s1,s1,136
    80003590:	ff3498e3          	bne	s1,s3,80003580 <iinit+0x3e>
}
    80003594:	70a2                	ld	ra,40(sp)
    80003596:	7402                	ld	s0,32(sp)
    80003598:	64e2                	ld	s1,24(sp)
    8000359a:	6942                	ld	s2,16(sp)
    8000359c:	69a2                	ld	s3,8(sp)
    8000359e:	6145                	addi	sp,sp,48
    800035a0:	8082                	ret

00000000800035a2 <ialloc>:
{
    800035a2:	715d                	addi	sp,sp,-80
    800035a4:	e486                	sd	ra,72(sp)
    800035a6:	e0a2                	sd	s0,64(sp)
    800035a8:	fc26                	sd	s1,56(sp)
    800035aa:	f84a                	sd	s2,48(sp)
    800035ac:	f44e                	sd	s3,40(sp)
    800035ae:	f052                	sd	s4,32(sp)
    800035b0:	ec56                	sd	s5,24(sp)
    800035b2:	e85a                	sd	s6,16(sp)
    800035b4:	e45e                	sd	s7,8(sp)
    800035b6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b8:	0001c717          	auipc	a4,0x1c
    800035bc:	1fc72703          	lw	a4,508(a4) # 8001f7b4 <sb+0xc>
    800035c0:	4785                	li	a5,1
    800035c2:	04e7fa63          	bgeu	a5,a4,80003616 <ialloc+0x74>
    800035c6:	8aaa                	mv	s5,a0
    800035c8:	8bae                	mv	s7,a1
    800035ca:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035cc:	0001ca17          	auipc	s4,0x1c
    800035d0:	1dca0a13          	addi	s4,s4,476 # 8001f7a8 <sb>
    800035d4:	00048b1b          	sext.w	s6,s1
    800035d8:	0044d593          	srli	a1,s1,0x4
    800035dc:	018a2783          	lw	a5,24(s4)
    800035e0:	9dbd                	addw	a1,a1,a5
    800035e2:	8556                	mv	a0,s5
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	954080e7          	jalr	-1708(ra) # 80002f38 <bread>
    800035ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ee:	05850993          	addi	s3,a0,88
    800035f2:	00f4f793          	andi	a5,s1,15
    800035f6:	079a                	slli	a5,a5,0x6
    800035f8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035fa:	00099783          	lh	a5,0(s3)
    800035fe:	c785                	beqz	a5,80003626 <ialloc+0x84>
    brelse(bp);
    80003600:	00000097          	auipc	ra,0x0
    80003604:	a68080e7          	jalr	-1432(ra) # 80003068 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003608:	0485                	addi	s1,s1,1
    8000360a:	00ca2703          	lw	a4,12(s4)
    8000360e:	0004879b          	sext.w	a5,s1
    80003612:	fce7e1e3          	bltu	a5,a4,800035d4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003616:	00005517          	auipc	a0,0x5
    8000361a:	faa50513          	addi	a0,a0,-86 # 800085c0 <syscalls+0x178>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003626:	04000613          	li	a2,64
    8000362a:	4581                	li	a1,0
    8000362c:	854e                	mv	a0,s3
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	6b2080e7          	jalr	1714(ra) # 80000ce0 <memset>
      dip->type = type;
    80003636:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000363a:	854a                	mv	a0,s2
    8000363c:	00001097          	auipc	ra,0x1
    80003640:	ca8080e7          	jalr	-856(ra) # 800042e4 <log_write>
      brelse(bp);
    80003644:	854a                	mv	a0,s2
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	a22080e7          	jalr	-1502(ra) # 80003068 <brelse>
      return iget(dev, inum);
    8000364e:	85da                	mv	a1,s6
    80003650:	8556                	mv	a0,s5
    80003652:	00000097          	auipc	ra,0x0
    80003656:	db4080e7          	jalr	-588(ra) # 80003406 <iget>
}
    8000365a:	60a6                	ld	ra,72(sp)
    8000365c:	6406                	ld	s0,64(sp)
    8000365e:	74e2                	ld	s1,56(sp)
    80003660:	7942                	ld	s2,48(sp)
    80003662:	79a2                	ld	s3,40(sp)
    80003664:	7a02                	ld	s4,32(sp)
    80003666:	6ae2                	ld	s5,24(sp)
    80003668:	6b42                	ld	s6,16(sp)
    8000366a:	6ba2                	ld	s7,8(sp)
    8000366c:	6161                	addi	sp,sp,80
    8000366e:	8082                	ret

0000000080003670 <iupdate>:
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	e04a                	sd	s2,0(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000367e:	415c                	lw	a5,4(a0)
    80003680:	0047d79b          	srliw	a5,a5,0x4
    80003684:	0001c597          	auipc	a1,0x1c
    80003688:	13c5a583          	lw	a1,316(a1) # 8001f7c0 <sb+0x18>
    8000368c:	9dbd                	addw	a1,a1,a5
    8000368e:	4108                	lw	a0,0(a0)
    80003690:	00000097          	auipc	ra,0x0
    80003694:	8a8080e7          	jalr	-1880(ra) # 80002f38 <bread>
    80003698:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000369a:	05850793          	addi	a5,a0,88
    8000369e:	40c8                	lw	a0,4(s1)
    800036a0:	893d                	andi	a0,a0,15
    800036a2:	051a                	slli	a0,a0,0x6
    800036a4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036a6:	04449703          	lh	a4,68(s1)
    800036aa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036ae:	04649703          	lh	a4,70(s1)
    800036b2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036b6:	04849703          	lh	a4,72(s1)
    800036ba:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036be:	04a49703          	lh	a4,74(s1)
    800036c2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036c6:	44f8                	lw	a4,76(s1)
    800036c8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ca:	03400613          	li	a2,52
    800036ce:	05048593          	addi	a1,s1,80
    800036d2:	0531                	addi	a0,a0,12
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	66c080e7          	jalr	1644(ra) # 80000d40 <memmove>
  log_write(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	c06080e7          	jalr	-1018(ra) # 800042e4 <log_write>
  brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	980080e7          	jalr	-1664(ra) # 80003068 <brelse>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6902                	ld	s2,0(sp)
    800036f8:	6105                	addi	sp,sp,32
    800036fa:	8082                	ret

00000000800036fc <idup>:
{
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003708:	0001c517          	auipc	a0,0x1c
    8000370c:	0c050513          	addi	a0,a0,192 # 8001f7c8 <itable>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
  ip->ref++;
    80003718:	449c                	lw	a5,8(s1)
    8000371a:	2785                	addiw	a5,a5,1
    8000371c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000371e:	0001c517          	auipc	a0,0x1c
    80003722:	0aa50513          	addi	a0,a0,170 # 8001f7c8 <itable>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
}
    8000372e:	8526                	mv	a0,s1
    80003730:	60e2                	ld	ra,24(sp)
    80003732:	6442                	ld	s0,16(sp)
    80003734:	64a2                	ld	s1,8(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <ilock>:
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	e04a                	sd	s2,0(sp)
    80003744:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003746:	c115                	beqz	a0,8000376a <ilock+0x30>
    80003748:	84aa                	mv	s1,a0
    8000374a:	451c                	lw	a5,8(a0)
    8000374c:	00f05f63          	blez	a5,8000376a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003750:	0541                	addi	a0,a0,16
    80003752:	00001097          	auipc	ra,0x1
    80003756:	cb2080e7          	jalr	-846(ra) # 80004404 <acquiresleep>
  if(ip->valid == 0){
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	cf99                	beqz	a5,8000377a <ilock+0x40>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret
    panic("ilock");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	e6e50513          	addi	a0,a0,-402 # 800085d8 <syscalls+0x190>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377a:	40dc                	lw	a5,4(s1)
    8000377c:	0047d79b          	srliw	a5,a5,0x4
    80003780:	0001c597          	auipc	a1,0x1c
    80003784:	0405a583          	lw	a1,64(a1) # 8001f7c0 <sb+0x18>
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	4088                	lw	a0,0(s1)
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	7ac080e7          	jalr	1964(ra) # 80002f38 <bread>
    80003794:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003796:	05850593          	addi	a1,a0,88
    8000379a:	40dc                	lw	a5,4(s1)
    8000379c:	8bbd                	andi	a5,a5,15
    8000379e:	079a                	slli	a5,a5,0x6
    800037a0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a2:	00059783          	lh	a5,0(a1)
    800037a6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037aa:	00259783          	lh	a5,2(a1)
    800037ae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b2:	00459783          	lh	a5,4(a1)
    800037b6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ba:	00659783          	lh	a5,6(a1)
    800037be:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c2:	459c                	lw	a5,8(a1)
    800037c4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c6:	03400613          	li	a2,52
    800037ca:	05b1                	addi	a1,a1,12
    800037cc:	05048513          	addi	a0,s1,80
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	570080e7          	jalr	1392(ra) # 80000d40 <memmove>
    brelse(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00000097          	auipc	ra,0x0
    800037de:	88e080e7          	jalr	-1906(ra) # 80003068 <brelse>
    ip->valid = 1;
    800037e2:	4785                	li	a5,1
    800037e4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e6:	04449783          	lh	a5,68(s1)
    800037ea:	fbb5                	bnez	a5,8000375e <ilock+0x24>
      panic("ilock: no type");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	df450513          	addi	a0,a0,-524 # 800085e0 <syscalls+0x198>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d4a080e7          	jalr	-694(ra) # 8000053e <panic>

00000000800037fc <iunlock>:
{
    800037fc:	1101                	addi	sp,sp,-32
    800037fe:	ec06                	sd	ra,24(sp)
    80003800:	e822                	sd	s0,16(sp)
    80003802:	e426                	sd	s1,8(sp)
    80003804:	e04a                	sd	s2,0(sp)
    80003806:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003808:	c905                	beqz	a0,80003838 <iunlock+0x3c>
    8000380a:	84aa                	mv	s1,a0
    8000380c:	01050913          	addi	s2,a0,16
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	c8c080e7          	jalr	-884(ra) # 8000449e <holdingsleep>
    8000381a:	cd19                	beqz	a0,80003838 <iunlock+0x3c>
    8000381c:	449c                	lw	a5,8(s1)
    8000381e:	00f05d63          	blez	a5,80003838 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	c36080e7          	jalr	-970(ra) # 8000445a <releasesleep>
}
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6902                	ld	s2,0(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret
    panic("iunlock");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	db850513          	addi	a0,a0,-584 # 800085f0 <syscalls+0x1a8>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cfe080e7          	jalr	-770(ra) # 8000053e <panic>

0000000080003848 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003848:	7179                	addi	sp,sp,-48
    8000384a:	f406                	sd	ra,40(sp)
    8000384c:	f022                	sd	s0,32(sp)
    8000384e:	ec26                	sd	s1,24(sp)
    80003850:	e84a                	sd	s2,16(sp)
    80003852:	e44e                	sd	s3,8(sp)
    80003854:	e052                	sd	s4,0(sp)
    80003856:	1800                	addi	s0,sp,48
    80003858:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000385a:	05050493          	addi	s1,a0,80
    8000385e:	08050913          	addi	s2,a0,128
    80003862:	a021                	j	8000386a <itrunc+0x22>
    80003864:	0491                	addi	s1,s1,4
    80003866:	01248d63          	beq	s1,s2,80003880 <itrunc+0x38>
    if(ip->addrs[i]){
    8000386a:	408c                	lw	a1,0(s1)
    8000386c:	dde5                	beqz	a1,80003864 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000386e:	0009a503          	lw	a0,0(s3)
    80003872:	00000097          	auipc	ra,0x0
    80003876:	90c080e7          	jalr	-1780(ra) # 8000317e <bfree>
      ip->addrs[i] = 0;
    8000387a:	0004a023          	sw	zero,0(s1)
    8000387e:	b7dd                	j	80003864 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003880:	0809a583          	lw	a1,128(s3)
    80003884:	e185                	bnez	a1,800038a4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003886:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000388a:	854e                	mv	a0,s3
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	de4080e7          	jalr	-540(ra) # 80003670 <iupdate>
}
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6a02                	ld	s4,0(sp)
    800038a0:	6145                	addi	sp,sp,48
    800038a2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	fffff097          	auipc	ra,0xfffff
    800038ac:	690080e7          	jalr	1680(ra) # 80002f38 <bread>
    800038b0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b2:	05850493          	addi	s1,a0,88
    800038b6:	45850913          	addi	s2,a0,1112
    800038ba:	a811                	j	800038ce <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038bc:	0009a503          	lw	a0,0(s3)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	8be080e7          	jalr	-1858(ra) # 8000317e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038c8:	0491                	addi	s1,s1,4
    800038ca:	01248563          	beq	s1,s2,800038d4 <itrunc+0x8c>
      if(a[j])
    800038ce:	408c                	lw	a1,0(s1)
    800038d0:	dde5                	beqz	a1,800038c8 <itrunc+0x80>
    800038d2:	b7ed                	j	800038bc <itrunc+0x74>
    brelse(bp);
    800038d4:	8552                	mv	a0,s4
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	792080e7          	jalr	1938(ra) # 80003068 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038de:	0809a583          	lw	a1,128(s3)
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	898080e7          	jalr	-1896(ra) # 8000317e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ee:	0809a023          	sw	zero,128(s3)
    800038f2:	bf51                	j	80003886 <itrunc+0x3e>

00000000800038f4 <iput>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003902:	0001c517          	auipc	a0,0x1c
    80003906:	ec650513          	addi	a0,a0,-314 # 8001f7c8 <itable>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	2da080e7          	jalr	730(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003912:	4498                	lw	a4,8(s1)
    80003914:	4785                	li	a5,1
    80003916:	02f70363          	beq	a4,a5,8000393c <iput+0x48>
  ip->ref--;
    8000391a:	449c                	lw	a5,8(s1)
    8000391c:	37fd                	addiw	a5,a5,-1
    8000391e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003920:	0001c517          	auipc	a0,0x1c
    80003924:	ea850513          	addi	a0,a0,-344 # 8001f7c8 <itable>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	370080e7          	jalr	880(ra) # 80000c98 <release>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393c:	40bc                	lw	a5,64(s1)
    8000393e:	dff1                	beqz	a5,8000391a <iput+0x26>
    80003940:	04a49783          	lh	a5,74(s1)
    80003944:	fbf9                	bnez	a5,8000391a <iput+0x26>
    acquiresleep(&ip->lock);
    80003946:	01048913          	addi	s2,s1,16
    8000394a:	854a                	mv	a0,s2
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	ab8080e7          	jalr	-1352(ra) # 80004404 <acquiresleep>
    release(&itable.lock);
    80003954:	0001c517          	auipc	a0,0x1c
    80003958:	e7450513          	addi	a0,a0,-396 # 8001f7c8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	33c080e7          	jalr	828(ra) # 80000c98 <release>
    itrunc(ip);
    80003964:	8526                	mv	a0,s1
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	ee2080e7          	jalr	-286(ra) # 80003848 <itrunc>
    ip->type = 0;
    8000396e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	cfc080e7          	jalr	-772(ra) # 80003670 <iupdate>
    ip->valid = 0;
    8000397c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ad8080e7          	jalr	-1320(ra) # 8000445a <releasesleep>
    acquire(&itable.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	e3e50513          	addi	a0,a0,-450 # 8001f7c8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	252080e7          	jalr	594(ra) # 80000be4 <acquire>
    8000399a:	b741                	j	8000391a <iput+0x26>

000000008000399c <iunlockput>:
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	1000                	addi	s0,sp,32
    800039a6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	e54080e7          	jalr	-428(ra) # 800037fc <iunlock>
  iput(ip);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	f42080e7          	jalr	-190(ra) # 800038f4 <iput>
}
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	64a2                	ld	s1,8(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret

00000000800039c4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c4:	1141                	addi	sp,sp,-16
    800039c6:	e422                	sd	s0,8(sp)
    800039c8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ca:	411c                	lw	a5,0(a0)
    800039cc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039ce:	415c                	lw	a5,4(a0)
    800039d0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d2:	04451783          	lh	a5,68(a0)
    800039d6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039da:	04a51783          	lh	a5,74(a0)
    800039de:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e2:	04c56783          	lwu	a5,76(a0)
    800039e6:	e99c                	sd	a5,16(a1)
}
    800039e8:	6422                	ld	s0,8(sp)
    800039ea:	0141                	addi	sp,sp,16
    800039ec:	8082                	ret

00000000800039ee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ee:	457c                	lw	a5,76(a0)
    800039f0:	0ed7e963          	bltu	a5,a3,80003ae2 <readi+0xf4>
{
    800039f4:	7159                	addi	sp,sp,-112
    800039f6:	f486                	sd	ra,104(sp)
    800039f8:	f0a2                	sd	s0,96(sp)
    800039fa:	eca6                	sd	s1,88(sp)
    800039fc:	e8ca                	sd	s2,80(sp)
    800039fe:	e4ce                	sd	s3,72(sp)
    80003a00:	e0d2                	sd	s4,64(sp)
    80003a02:	fc56                	sd	s5,56(sp)
    80003a04:	f85a                	sd	s6,48(sp)
    80003a06:	f45e                	sd	s7,40(sp)
    80003a08:	f062                	sd	s8,32(sp)
    80003a0a:	ec66                	sd	s9,24(sp)
    80003a0c:	e86a                	sd	s10,16(sp)
    80003a0e:	e46e                	sd	s11,8(sp)
    80003a10:	1880                	addi	s0,sp,112
    80003a12:	8baa                	mv	s7,a0
    80003a14:	8c2e                	mv	s8,a1
    80003a16:	8ab2                	mv	s5,a2
    80003a18:	84b6                	mv	s1,a3
    80003a1a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a20:	0ad76063          	bltu	a4,a3,80003ac0 <readi+0xd2>
  if(off + n > ip->size)
    80003a24:	00e7f463          	bgeu	a5,a4,80003a2c <readi+0x3e>
    n = ip->size - off;
    80003a28:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2c:	0a0b0963          	beqz	s6,80003ade <readi+0xf0>
    80003a30:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a32:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a36:	5cfd                	li	s9,-1
    80003a38:	a82d                	j	80003a72 <readi+0x84>
    80003a3a:	020a1d93          	slli	s11,s4,0x20
    80003a3e:	020ddd93          	srli	s11,s11,0x20
    80003a42:	05890613          	addi	a2,s2,88
    80003a46:	86ee                	mv	a3,s11
    80003a48:	963a                	add	a2,a2,a4
    80003a4a:	85d6                	mv	a1,s5
    80003a4c:	8562                	mv	a0,s8
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	a22080e7          	jalr	-1502(ra) # 80002470 <either_copyout>
    80003a56:	05950d63          	beq	a0,s9,80003ab0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	60c080e7          	jalr	1548(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a64:	013a09bb          	addw	s3,s4,s3
    80003a68:	009a04bb          	addw	s1,s4,s1
    80003a6c:	9aee                	add	s5,s5,s11
    80003a6e:	0569f763          	bgeu	s3,s6,80003abc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a72:	000ba903          	lw	s2,0(s7)
    80003a76:	00a4d59b          	srliw	a1,s1,0xa
    80003a7a:	855e                	mv	a0,s7
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	8b0080e7          	jalr	-1872(ra) # 8000332c <bmap>
    80003a84:	0005059b          	sext.w	a1,a0
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	4ae080e7          	jalr	1198(ra) # 80002f38 <bread>
    80003a92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a94:	3ff4f713          	andi	a4,s1,1023
    80003a98:	40ed07bb          	subw	a5,s10,a4
    80003a9c:	413b06bb          	subw	a3,s6,s3
    80003aa0:	8a3e                	mv	s4,a5
    80003aa2:	2781                	sext.w	a5,a5
    80003aa4:	0006861b          	sext.w	a2,a3
    80003aa8:	f8f679e3          	bgeu	a2,a5,80003a3a <readi+0x4c>
    80003aac:	8a36                	mv	s4,a3
    80003aae:	b771                	j	80003a3a <readi+0x4c>
      brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	5b6080e7          	jalr	1462(ra) # 80003068 <brelse>
      tot = -1;
    80003aba:	59fd                	li	s3,-1
  }
  return tot;
    80003abc:	0009851b          	sext.w	a0,s3
}
    80003ac0:	70a6                	ld	ra,104(sp)
    80003ac2:	7406                	ld	s0,96(sp)
    80003ac4:	64e6                	ld	s1,88(sp)
    80003ac6:	6946                	ld	s2,80(sp)
    80003ac8:	69a6                	ld	s3,72(sp)
    80003aca:	6a06                	ld	s4,64(sp)
    80003acc:	7ae2                	ld	s5,56(sp)
    80003ace:	7b42                	ld	s6,48(sp)
    80003ad0:	7ba2                	ld	s7,40(sp)
    80003ad2:	7c02                	ld	s8,32(sp)
    80003ad4:	6ce2                	ld	s9,24(sp)
    80003ad6:	6d42                	ld	s10,16(sp)
    80003ad8:	6da2                	ld	s11,8(sp)
    80003ada:	6165                	addi	sp,sp,112
    80003adc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ade:	89da                	mv	s3,s6
    80003ae0:	bff1                	j	80003abc <readi+0xce>
    return 0;
    80003ae2:	4501                	li	a0,0
}
    80003ae4:	8082                	ret

0000000080003ae6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae6:	457c                	lw	a5,76(a0)
    80003ae8:	10d7e863          	bltu	a5,a3,80003bf8 <writei+0x112>
{
    80003aec:	7159                	addi	sp,sp,-112
    80003aee:	f486                	sd	ra,104(sp)
    80003af0:	f0a2                	sd	s0,96(sp)
    80003af2:	eca6                	sd	s1,88(sp)
    80003af4:	e8ca                	sd	s2,80(sp)
    80003af6:	e4ce                	sd	s3,72(sp)
    80003af8:	e0d2                	sd	s4,64(sp)
    80003afa:	fc56                	sd	s5,56(sp)
    80003afc:	f85a                	sd	s6,48(sp)
    80003afe:	f45e                	sd	s7,40(sp)
    80003b00:	f062                	sd	s8,32(sp)
    80003b02:	ec66                	sd	s9,24(sp)
    80003b04:	e86a                	sd	s10,16(sp)
    80003b06:	e46e                	sd	s11,8(sp)
    80003b08:	1880                	addi	s0,sp,112
    80003b0a:	8b2a                	mv	s6,a0
    80003b0c:	8c2e                	mv	s8,a1
    80003b0e:	8ab2                	mv	s5,a2
    80003b10:	8936                	mv	s2,a3
    80003b12:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b14:	00e687bb          	addw	a5,a3,a4
    80003b18:	0ed7e263          	bltu	a5,a3,80003bfc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1c:	00043737          	lui	a4,0x43
    80003b20:	0ef76063          	bltu	a4,a5,80003c00 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b24:	0c0b8863          	beqz	s7,80003bf4 <writei+0x10e>
    80003b28:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b2e:	5cfd                	li	s9,-1
    80003b30:	a091                	j	80003b74 <writei+0x8e>
    80003b32:	02099d93          	slli	s11,s3,0x20
    80003b36:	020ddd93          	srli	s11,s11,0x20
    80003b3a:	05848513          	addi	a0,s1,88
    80003b3e:	86ee                	mv	a3,s11
    80003b40:	8656                	mv	a2,s5
    80003b42:	85e2                	mv	a1,s8
    80003b44:	953a                	add	a0,a0,a4
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	980080e7          	jalr	-1664(ra) # 800024c6 <either_copyin>
    80003b4e:	07950263          	beq	a0,s9,80003bb2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b52:	8526                	mv	a0,s1
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	790080e7          	jalr	1936(ra) # 800042e4 <log_write>
    brelse(bp);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	fffff097          	auipc	ra,0xfffff
    80003b62:	50a080e7          	jalr	1290(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b66:	01498a3b          	addw	s4,s3,s4
    80003b6a:	0129893b          	addw	s2,s3,s2
    80003b6e:	9aee                	add	s5,s5,s11
    80003b70:	057a7663          	bgeu	s4,s7,80003bbc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b74:	000b2483          	lw	s1,0(s6)
    80003b78:	00a9559b          	srliw	a1,s2,0xa
    80003b7c:	855a                	mv	a0,s6
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	7ae080e7          	jalr	1966(ra) # 8000332c <bmap>
    80003b86:	0005059b          	sext.w	a1,a0
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	3ac080e7          	jalr	940(ra) # 80002f38 <bread>
    80003b94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b96:	3ff97713          	andi	a4,s2,1023
    80003b9a:	40ed07bb          	subw	a5,s10,a4
    80003b9e:	414b86bb          	subw	a3,s7,s4
    80003ba2:	89be                	mv	s3,a5
    80003ba4:	2781                	sext.w	a5,a5
    80003ba6:	0006861b          	sext.w	a2,a3
    80003baa:	f8f674e3          	bgeu	a2,a5,80003b32 <writei+0x4c>
    80003bae:	89b6                	mv	s3,a3
    80003bb0:	b749                	j	80003b32 <writei+0x4c>
      brelse(bp);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	4b4080e7          	jalr	1204(ra) # 80003068 <brelse>
  }

  if(off > ip->size)
    80003bbc:	04cb2783          	lw	a5,76(s6)
    80003bc0:	0127f463          	bgeu	a5,s2,80003bc8 <writei+0xe2>
    ip->size = off;
    80003bc4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bc8:	855a                	mv	a0,s6
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	aa6080e7          	jalr	-1370(ra) # 80003670 <iupdate>

  return tot;
    80003bd2:	000a051b          	sext.w	a0,s4
}
    80003bd6:	70a6                	ld	ra,104(sp)
    80003bd8:	7406                	ld	s0,96(sp)
    80003bda:	64e6                	ld	s1,88(sp)
    80003bdc:	6946                	ld	s2,80(sp)
    80003bde:	69a6                	ld	s3,72(sp)
    80003be0:	6a06                	ld	s4,64(sp)
    80003be2:	7ae2                	ld	s5,56(sp)
    80003be4:	7b42                	ld	s6,48(sp)
    80003be6:	7ba2                	ld	s7,40(sp)
    80003be8:	7c02                	ld	s8,32(sp)
    80003bea:	6ce2                	ld	s9,24(sp)
    80003bec:	6d42                	ld	s10,16(sp)
    80003bee:	6da2                	ld	s11,8(sp)
    80003bf0:	6165                	addi	sp,sp,112
    80003bf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf4:	8a5e                	mv	s4,s7
    80003bf6:	bfc9                	j	80003bc8 <writei+0xe2>
    return -1;
    80003bf8:	557d                	li	a0,-1
}
    80003bfa:	8082                	ret
    return -1;
    80003bfc:	557d                	li	a0,-1
    80003bfe:	bfe1                	j	80003bd6 <writei+0xf0>
    return -1;
    80003c00:	557d                	li	a0,-1
    80003c02:	bfd1                	j	80003bd6 <writei+0xf0>

0000000080003c04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c04:	1141                	addi	sp,sp,-16
    80003c06:	e406                	sd	ra,8(sp)
    80003c08:	e022                	sd	s0,0(sp)
    80003c0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c0c:	4639                	li	a2,14
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	1aa080e7          	jalr	426(ra) # 80000db8 <strncmp>
}
    80003c16:	60a2                	ld	ra,8(sp)
    80003c18:	6402                	ld	s0,0(sp)
    80003c1a:	0141                	addi	sp,sp,16
    80003c1c:	8082                	ret

0000000080003c1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c1e:	7139                	addi	sp,sp,-64
    80003c20:	fc06                	sd	ra,56(sp)
    80003c22:	f822                	sd	s0,48(sp)
    80003c24:	f426                	sd	s1,40(sp)
    80003c26:	f04a                	sd	s2,32(sp)
    80003c28:	ec4e                	sd	s3,24(sp)
    80003c2a:	e852                	sd	s4,16(sp)
    80003c2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c2e:	04451703          	lh	a4,68(a0)
    80003c32:	4785                	li	a5,1
    80003c34:	00f71a63          	bne	a4,a5,80003c48 <dirlookup+0x2a>
    80003c38:	892a                	mv	s2,a0
    80003c3a:	89ae                	mv	s3,a1
    80003c3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3e:	457c                	lw	a5,76(a0)
    80003c40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c44:	e79d                	bnez	a5,80003c72 <dirlookup+0x54>
    80003c46:	a8a5                	j	80003cbe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c48:	00005517          	auipc	a0,0x5
    80003c4c:	9b050513          	addi	a0,a0,-1616 # 800085f8 <syscalls+0x1b0>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	8ee080e7          	jalr	-1810(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	9b850513          	addi	a0,a0,-1608 # 80008610 <syscalls+0x1c8>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8de080e7          	jalr	-1826(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c68:	24c1                	addiw	s1,s1,16
    80003c6a:	04c92783          	lw	a5,76(s2)
    80003c6e:	04f4f763          	bgeu	s1,a5,80003cbc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c72:	4741                	li	a4,16
    80003c74:	86a6                	mv	a3,s1
    80003c76:	fc040613          	addi	a2,s0,-64
    80003c7a:	4581                	li	a1,0
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	d70080e7          	jalr	-656(ra) # 800039ee <readi>
    80003c86:	47c1                	li	a5,16
    80003c88:	fcf518e3          	bne	a0,a5,80003c58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c8c:	fc045783          	lhu	a5,-64(s0)
    80003c90:	dfe1                	beqz	a5,80003c68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c92:	fc240593          	addi	a1,s0,-62
    80003c96:	854e                	mv	a0,s3
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	f6c080e7          	jalr	-148(ra) # 80003c04 <namecmp>
    80003ca0:	f561                	bnez	a0,80003c68 <dirlookup+0x4a>
      if(poff)
    80003ca2:	000a0463          	beqz	s4,80003caa <dirlookup+0x8c>
        *poff = off;
    80003ca6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003caa:	fc045583          	lhu	a1,-64(s0)
    80003cae:	00092503          	lw	a0,0(s2)
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	754080e7          	jalr	1876(ra) # 80003406 <iget>
    80003cba:	a011                	j	80003cbe <dirlookup+0xa0>
  return 0;
    80003cbc:	4501                	li	a0,0
}
    80003cbe:	70e2                	ld	ra,56(sp)
    80003cc0:	7442                	ld	s0,48(sp)
    80003cc2:	74a2                	ld	s1,40(sp)
    80003cc4:	7902                	ld	s2,32(sp)
    80003cc6:	69e2                	ld	s3,24(sp)
    80003cc8:	6a42                	ld	s4,16(sp)
    80003cca:	6121                	addi	sp,sp,64
    80003ccc:	8082                	ret

0000000080003cce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cce:	711d                	addi	sp,sp,-96
    80003cd0:	ec86                	sd	ra,88(sp)
    80003cd2:	e8a2                	sd	s0,80(sp)
    80003cd4:	e4a6                	sd	s1,72(sp)
    80003cd6:	e0ca                	sd	s2,64(sp)
    80003cd8:	fc4e                	sd	s3,56(sp)
    80003cda:	f852                	sd	s4,48(sp)
    80003cdc:	f456                	sd	s5,40(sp)
    80003cde:	f05a                	sd	s6,32(sp)
    80003ce0:	ec5e                	sd	s7,24(sp)
    80003ce2:	e862                	sd	s8,16(sp)
    80003ce4:	e466                	sd	s9,8(sp)
    80003ce6:	1080                	addi	s0,sp,96
    80003ce8:	84aa                	mv	s1,a0
    80003cea:	8b2e                	mv	s6,a1
    80003cec:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cee:	00054703          	lbu	a4,0(a0)
    80003cf2:	02f00793          	li	a5,47
    80003cf6:	02f70363          	beq	a4,a5,80003d1c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cfa:	ffffe097          	auipc	ra,0xffffe
    80003cfe:	cb6080e7          	jalr	-842(ra) # 800019b0 <myproc>
    80003d02:	15053503          	ld	a0,336(a0)
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	9f6080e7          	jalr	-1546(ra) # 800036fc <idup>
    80003d0e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d10:	02f00913          	li	s2,47
  len = path - s;
    80003d14:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d16:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d18:	4c05                	li	s8,1
    80003d1a:	a865                	j	80003dd2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d1c:	4585                	li	a1,1
    80003d1e:	4505                	li	a0,1
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	6e6080e7          	jalr	1766(ra) # 80003406 <iget>
    80003d28:	89aa                	mv	s3,a0
    80003d2a:	b7dd                	j	80003d10 <namex+0x42>
      iunlockput(ip);
    80003d2c:	854e                	mv	a0,s3
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	c6e080e7          	jalr	-914(ra) # 8000399c <iunlockput>
      return 0;
    80003d36:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d38:	854e                	mv	a0,s3
    80003d3a:	60e6                	ld	ra,88(sp)
    80003d3c:	6446                	ld	s0,80(sp)
    80003d3e:	64a6                	ld	s1,72(sp)
    80003d40:	6906                	ld	s2,64(sp)
    80003d42:	79e2                	ld	s3,56(sp)
    80003d44:	7a42                	ld	s4,48(sp)
    80003d46:	7aa2                	ld	s5,40(sp)
    80003d48:	7b02                	ld	s6,32(sp)
    80003d4a:	6be2                	ld	s7,24(sp)
    80003d4c:	6c42                	ld	s8,16(sp)
    80003d4e:	6ca2                	ld	s9,8(sp)
    80003d50:	6125                	addi	sp,sp,96
    80003d52:	8082                	ret
      iunlock(ip);
    80003d54:	854e                	mv	a0,s3
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	aa6080e7          	jalr	-1370(ra) # 800037fc <iunlock>
      return ip;
    80003d5e:	bfe9                	j	80003d38 <namex+0x6a>
      iunlockput(ip);
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	c3a080e7          	jalr	-966(ra) # 8000399c <iunlockput>
      return 0;
    80003d6a:	89d2                	mv	s3,s4
    80003d6c:	b7f1                	j	80003d38 <namex+0x6a>
  len = path - s;
    80003d6e:	40b48633          	sub	a2,s1,a1
    80003d72:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d76:	094cd463          	bge	s9,s4,80003dfe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d7a:	4639                	li	a2,14
    80003d7c:	8556                	mv	a0,s5
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	fc2080e7          	jalr	-62(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	01279763          	bne	a5,s2,80003d98 <namex+0xca>
    path++;
    80003d8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d90:	0004c783          	lbu	a5,0(s1)
    80003d94:	ff278de3          	beq	a5,s2,80003d8e <namex+0xc0>
    ilock(ip);
    80003d98:	854e                	mv	a0,s3
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	9a0080e7          	jalr	-1632(ra) # 8000373a <ilock>
    if(ip->type != T_DIR){
    80003da2:	04499783          	lh	a5,68(s3)
    80003da6:	f98793e3          	bne	a5,s8,80003d2c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003daa:	000b0563          	beqz	s6,80003db4 <namex+0xe6>
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	d3cd                	beqz	a5,80003d54 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db4:	865e                	mv	a2,s7
    80003db6:	85d6                	mv	a1,s5
    80003db8:	854e                	mv	a0,s3
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	e64080e7          	jalr	-412(ra) # 80003c1e <dirlookup>
    80003dc2:	8a2a                	mv	s4,a0
    80003dc4:	dd51                	beqz	a0,80003d60 <namex+0x92>
    iunlockput(ip);
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	bd4080e7          	jalr	-1068(ra) # 8000399c <iunlockput>
    ip = next;
    80003dd0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	05279763          	bne	a5,s2,80003e24 <namex+0x156>
    path++;
    80003dda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	ff278de3          	beq	a5,s2,80003dda <namex+0x10c>
  if(*path == 0)
    80003de4:	c79d                	beqz	a5,80003e12 <namex+0x144>
    path++;
    80003de6:	85a6                	mv	a1,s1
  len = path - s;
    80003de8:	8a5e                	mv	s4,s7
    80003dea:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dec:	01278963          	beq	a5,s2,80003dfe <namex+0x130>
    80003df0:	dfbd                	beqz	a5,80003d6e <namex+0xa0>
    path++;
    80003df2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003df4:	0004c783          	lbu	a5,0(s1)
    80003df8:	ff279ce3          	bne	a5,s2,80003df0 <namex+0x122>
    80003dfc:	bf8d                	j	80003d6e <namex+0xa0>
    memmove(name, s, len);
    80003dfe:	2601                	sext.w	a2,a2
    80003e00:	8556                	mv	a0,s5
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	f3e080e7          	jalr	-194(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e0a:	9a56                	add	s4,s4,s5
    80003e0c:	000a0023          	sb	zero,0(s4)
    80003e10:	bf9d                	j	80003d86 <namex+0xb8>
  if(nameiparent){
    80003e12:	f20b03e3          	beqz	s6,80003d38 <namex+0x6a>
    iput(ip);
    80003e16:	854e                	mv	a0,s3
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	adc080e7          	jalr	-1316(ra) # 800038f4 <iput>
    return 0;
    80003e20:	4981                	li	s3,0
    80003e22:	bf19                	j	80003d38 <namex+0x6a>
  if(*path == 0)
    80003e24:	d7fd                	beqz	a5,80003e12 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	85a6                	mv	a1,s1
    80003e2c:	b7d1                	j	80003df0 <namex+0x122>

0000000080003e2e <dirlink>:
{
    80003e2e:	7139                	addi	sp,sp,-64
    80003e30:	fc06                	sd	ra,56(sp)
    80003e32:	f822                	sd	s0,48(sp)
    80003e34:	f426                	sd	s1,40(sp)
    80003e36:	f04a                	sd	s2,32(sp)
    80003e38:	ec4e                	sd	s3,24(sp)
    80003e3a:	e852                	sd	s4,16(sp)
    80003e3c:	0080                	addi	s0,sp,64
    80003e3e:	892a                	mv	s2,a0
    80003e40:	8a2e                	mv	s4,a1
    80003e42:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e44:	4601                	li	a2,0
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	dd8080e7          	jalr	-552(ra) # 80003c1e <dirlookup>
    80003e4e:	e93d                	bnez	a0,80003ec4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e50:	04c92483          	lw	s1,76(s2)
    80003e54:	c49d                	beqz	s1,80003e82 <dirlink+0x54>
    80003e56:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e58:	4741                	li	a4,16
    80003e5a:	86a6                	mv	a3,s1
    80003e5c:	fc040613          	addi	a2,s0,-64
    80003e60:	4581                	li	a1,0
    80003e62:	854a                	mv	a0,s2
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	b8a080e7          	jalr	-1142(ra) # 800039ee <readi>
    80003e6c:	47c1                	li	a5,16
    80003e6e:	06f51163          	bne	a0,a5,80003ed0 <dirlink+0xa2>
    if(de.inum == 0)
    80003e72:	fc045783          	lhu	a5,-64(s0)
    80003e76:	c791                	beqz	a5,80003e82 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e78:	24c1                	addiw	s1,s1,16
    80003e7a:	04c92783          	lw	a5,76(s2)
    80003e7e:	fcf4ede3          	bltu	s1,a5,80003e58 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e82:	4639                	li	a2,14
    80003e84:	85d2                	mv	a1,s4
    80003e86:	fc240513          	addi	a0,s0,-62
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	f6a080e7          	jalr	-150(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e92:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e96:	4741                	li	a4,16
    80003e98:	86a6                	mv	a3,s1
    80003e9a:	fc040613          	addi	a2,s0,-64
    80003e9e:	4581                	li	a1,0
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	c44080e7          	jalr	-956(ra) # 80003ae6 <writei>
    80003eaa:	872a                	mv	a4,a0
    80003eac:	47c1                	li	a5,16
  return 0;
    80003eae:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb0:	02f71863          	bne	a4,a5,80003ee0 <dirlink+0xb2>
}
    80003eb4:	70e2                	ld	ra,56(sp)
    80003eb6:	7442                	ld	s0,48(sp)
    80003eb8:	74a2                	ld	s1,40(sp)
    80003eba:	7902                	ld	s2,32(sp)
    80003ebc:	69e2                	ld	s3,24(sp)
    80003ebe:	6a42                	ld	s4,16(sp)
    80003ec0:	6121                	addi	sp,sp,64
    80003ec2:	8082                	ret
    iput(ip);
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	a30080e7          	jalr	-1488(ra) # 800038f4 <iput>
    return -1;
    80003ecc:	557d                	li	a0,-1
    80003ece:	b7dd                	j	80003eb4 <dirlink+0x86>
      panic("dirlink read");
    80003ed0:	00004517          	auipc	a0,0x4
    80003ed4:	75050513          	addi	a0,a0,1872 # 80008620 <syscalls+0x1d8>
    80003ed8:	ffffc097          	auipc	ra,0xffffc
    80003edc:	666080e7          	jalr	1638(ra) # 8000053e <panic>
    panic("dirlink");
    80003ee0:	00005517          	auipc	a0,0x5
    80003ee4:	85050513          	addi	a0,a0,-1968 # 80008730 <syscalls+0x2e8>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	656080e7          	jalr	1622(ra) # 8000053e <panic>

0000000080003ef0 <namei>:

struct inode*
namei(char *path)
{
    80003ef0:	1101                	addi	sp,sp,-32
    80003ef2:	ec06                	sd	ra,24(sp)
    80003ef4:	e822                	sd	s0,16(sp)
    80003ef6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef8:	fe040613          	addi	a2,s0,-32
    80003efc:	4581                	li	a1,0
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	dd0080e7          	jalr	-560(ra) # 80003cce <namex>
}
    80003f06:	60e2                	ld	ra,24(sp)
    80003f08:	6442                	ld	s0,16(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0e:	1141                	addi	sp,sp,-16
    80003f10:	e406                	sd	ra,8(sp)
    80003f12:	e022                	sd	s0,0(sp)
    80003f14:	0800                	addi	s0,sp,16
    80003f16:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f18:	4585                	li	a1,1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	db4080e7          	jalr	-588(ra) # 80003cce <namex>
}
    80003f22:	60a2                	ld	ra,8(sp)
    80003f24:	6402                	ld	s0,0(sp)
    80003f26:	0141                	addi	sp,sp,16
    80003f28:	8082                	ret

0000000080003f2a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f2a:	1101                	addi	sp,sp,-32
    80003f2c:	ec06                	sd	ra,24(sp)
    80003f2e:	e822                	sd	s0,16(sp)
    80003f30:	e426                	sd	s1,8(sp)
    80003f32:	e04a                	sd	s2,0(sp)
    80003f34:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f36:	0001d917          	auipc	s2,0x1d
    80003f3a:	33a90913          	addi	s2,s2,826 # 80021270 <log>
    80003f3e:	01892583          	lw	a1,24(s2)
    80003f42:	02892503          	lw	a0,40(s2)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	ff2080e7          	jalr	-14(ra) # 80002f38 <bread>
    80003f4e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f50:	02c92683          	lw	a3,44(s2)
    80003f54:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f56:	02d05763          	blez	a3,80003f84 <write_head+0x5a>
    80003f5a:	0001d797          	auipc	a5,0x1d
    80003f5e:	34678793          	addi	a5,a5,838 # 800212a0 <log+0x30>
    80003f62:	05c50713          	addi	a4,a0,92
    80003f66:	36fd                	addiw	a3,a3,-1
    80003f68:	1682                	slli	a3,a3,0x20
    80003f6a:	9281                	srli	a3,a3,0x20
    80003f6c:	068a                	slli	a3,a3,0x2
    80003f6e:	0001d617          	auipc	a2,0x1d
    80003f72:	33660613          	addi	a2,a2,822 # 800212a4 <log+0x34>
    80003f76:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f78:	4390                	lw	a2,0(a5)
    80003f7a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7c:	0791                	addi	a5,a5,4
    80003f7e:	0711                	addi	a4,a4,4
    80003f80:	fed79ce3          	bne	a5,a3,80003f78 <write_head+0x4e>
  }
  bwrite(buf);
    80003f84:	8526                	mv	a0,s1
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	0a4080e7          	jalr	164(ra) # 8000302a <bwrite>
  brelse(buf);
    80003f8e:	8526                	mv	a0,s1
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	0d8080e7          	jalr	216(ra) # 80003068 <brelse>
}
    80003f98:	60e2                	ld	ra,24(sp)
    80003f9a:	6442                	ld	s0,16(sp)
    80003f9c:	64a2                	ld	s1,8(sp)
    80003f9e:	6902                	ld	s2,0(sp)
    80003fa0:	6105                	addi	sp,sp,32
    80003fa2:	8082                	ret

0000000080003fa4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa4:	0001d797          	auipc	a5,0x1d
    80003fa8:	2f87a783          	lw	a5,760(a5) # 8002129c <log+0x2c>
    80003fac:	0af05d63          	blez	a5,80004066 <install_trans+0xc2>
{
    80003fb0:	7139                	addi	sp,sp,-64
    80003fb2:	fc06                	sd	ra,56(sp)
    80003fb4:	f822                	sd	s0,48(sp)
    80003fb6:	f426                	sd	s1,40(sp)
    80003fb8:	f04a                	sd	s2,32(sp)
    80003fba:	ec4e                	sd	s3,24(sp)
    80003fbc:	e852                	sd	s4,16(sp)
    80003fbe:	e456                	sd	s5,8(sp)
    80003fc0:	e05a                	sd	s6,0(sp)
    80003fc2:	0080                	addi	s0,sp,64
    80003fc4:	8b2a                	mv	s6,a0
    80003fc6:	0001da97          	auipc	s5,0x1d
    80003fca:	2daa8a93          	addi	s5,s5,730 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd0:	0001d997          	auipc	s3,0x1d
    80003fd4:	2a098993          	addi	s3,s3,672 # 80021270 <log>
    80003fd8:	a035                	j	80004004 <install_trans+0x60>
      bunpin(dbuf);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	166080e7          	jalr	358(ra) # 80003142 <bunpin>
    brelse(lbuf);
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	082080e7          	jalr	130(ra) # 80003068 <brelse>
    brelse(dbuf);
    80003fee:	8526                	mv	a0,s1
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	078080e7          	jalr	120(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff8:	2a05                	addiw	s4,s4,1
    80003ffa:	0a91                	addi	s5,s5,4
    80003ffc:	02c9a783          	lw	a5,44(s3)
    80004000:	04fa5963          	bge	s4,a5,80004052 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004004:	0189a583          	lw	a1,24(s3)
    80004008:	014585bb          	addw	a1,a1,s4
    8000400c:	2585                	addiw	a1,a1,1
    8000400e:	0289a503          	lw	a0,40(s3)
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	f26080e7          	jalr	-218(ra) # 80002f38 <bread>
    8000401a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401c:	000aa583          	lw	a1,0(s5)
    80004020:	0289a503          	lw	a0,40(s3)
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	f14080e7          	jalr	-236(ra) # 80002f38 <bread>
    8000402c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000402e:	40000613          	li	a2,1024
    80004032:	05890593          	addi	a1,s2,88
    80004036:	05850513          	addi	a0,a0,88
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	d06080e7          	jalr	-762(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	fe6080e7          	jalr	-26(ra) # 8000302a <bwrite>
    if(recovering == 0)
    8000404c:	f80b1ce3          	bnez	s6,80003fe4 <install_trans+0x40>
    80004050:	b769                	j	80003fda <install_trans+0x36>
}
    80004052:	70e2                	ld	ra,56(sp)
    80004054:	7442                	ld	s0,48(sp)
    80004056:	74a2                	ld	s1,40(sp)
    80004058:	7902                	ld	s2,32(sp)
    8000405a:	69e2                	ld	s3,24(sp)
    8000405c:	6a42                	ld	s4,16(sp)
    8000405e:	6aa2                	ld	s5,8(sp)
    80004060:	6b02                	ld	s6,0(sp)
    80004062:	6121                	addi	sp,sp,64
    80004064:	8082                	ret
    80004066:	8082                	ret

0000000080004068 <initlog>:
{
    80004068:	7179                	addi	sp,sp,-48
    8000406a:	f406                	sd	ra,40(sp)
    8000406c:	f022                	sd	s0,32(sp)
    8000406e:	ec26                	sd	s1,24(sp)
    80004070:	e84a                	sd	s2,16(sp)
    80004072:	e44e                	sd	s3,8(sp)
    80004074:	1800                	addi	s0,sp,48
    80004076:	892a                	mv	s2,a0
    80004078:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407a:	0001d497          	auipc	s1,0x1d
    8000407e:	1f648493          	addi	s1,s1,502 # 80021270 <log>
    80004082:	00004597          	auipc	a1,0x4
    80004086:	5ae58593          	addi	a1,a1,1454 # 80008630 <syscalls+0x1e8>
    8000408a:	8526                	mv	a0,s1
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	ac8080e7          	jalr	-1336(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004094:	0149a583          	lw	a1,20(s3)
    80004098:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409a:	0109a783          	lw	a5,16(s3)
    8000409e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a4:	854a                	mv	a0,s2
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	e92080e7          	jalr	-366(ra) # 80002f38 <bread>
  log.lh.n = lh->n;
    800040ae:	4d3c                	lw	a5,88(a0)
    800040b0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b2:	02f05563          	blez	a5,800040dc <initlog+0x74>
    800040b6:	05c50713          	addi	a4,a0,92
    800040ba:	0001d697          	auipc	a3,0x1d
    800040be:	1e668693          	addi	a3,a3,486 # 800212a0 <log+0x30>
    800040c2:	37fd                	addiw	a5,a5,-1
    800040c4:	1782                	slli	a5,a5,0x20
    800040c6:	9381                	srli	a5,a5,0x20
    800040c8:	078a                	slli	a5,a5,0x2
    800040ca:	06050613          	addi	a2,a0,96
    800040ce:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d0:	4310                	lw	a2,0(a4)
    800040d2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d4:	0711                	addi	a4,a4,4
    800040d6:	0691                	addi	a3,a3,4
    800040d8:	fef71ce3          	bne	a4,a5,800040d0 <initlog+0x68>
  brelse(buf);
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	f8c080e7          	jalr	-116(ra) # 80003068 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e4:	4505                	li	a0,1
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	ebe080e7          	jalr	-322(ra) # 80003fa4 <install_trans>
  log.lh.n = 0;
    800040ee:	0001d797          	auipc	a5,0x1d
    800040f2:	1a07a723          	sw	zero,430(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	e34080e7          	jalr	-460(ra) # 80003f2a <write_head>
}
    800040fe:	70a2                	ld	ra,40(sp)
    80004100:	7402                	ld	s0,32(sp)
    80004102:	64e2                	ld	s1,24(sp)
    80004104:	6942                	ld	s2,16(sp)
    80004106:	69a2                	ld	s3,8(sp)
    80004108:	6145                	addi	sp,sp,48
    8000410a:	8082                	ret

000000008000410c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	e426                	sd	s1,8(sp)
    80004114:	e04a                	sd	s2,0(sp)
    80004116:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004118:	0001d517          	auipc	a0,0x1d
    8000411c:	15850513          	addi	a0,a0,344 # 80021270 <log>
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	ac4080e7          	jalr	-1340(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	14848493          	addi	s1,s1,328 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	4979                	li	s2,30
    80004132:	a039                	j	80004140 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004134:	85a6                	mv	a1,s1
    80004136:	8526                	mv	a0,s1
    80004138:	ffffe097          	auipc	ra,0xffffe
    8000413c:	f94080e7          	jalr	-108(ra) # 800020cc <sleep>
    if(log.committing){
    80004140:	50dc                	lw	a5,36(s1)
    80004142:	fbed                	bnez	a5,80004134 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004144:	509c                	lw	a5,32(s1)
    80004146:	0017871b          	addiw	a4,a5,1
    8000414a:	0007069b          	sext.w	a3,a4
    8000414e:	0027179b          	slliw	a5,a4,0x2
    80004152:	9fb9                	addw	a5,a5,a4
    80004154:	0017979b          	slliw	a5,a5,0x1
    80004158:	54d8                	lw	a4,44(s1)
    8000415a:	9fb9                	addw	a5,a5,a4
    8000415c:	00f95963          	bge	s2,a5,8000416e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004160:	85a6                	mv	a1,s1
    80004162:	8526                	mv	a0,s1
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	f68080e7          	jalr	-152(ra) # 800020cc <sleep>
    8000416c:	bfd1                	j	80004140 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000416e:	0001d517          	auipc	a0,0x1d
    80004172:	10250513          	addi	a0,a0,258 # 80021270 <log>
    80004176:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6902                	ld	s2,0(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418c:	7139                	addi	sp,sp,-64
    8000418e:	fc06                	sd	ra,56(sp)
    80004190:	f822                	sd	s0,48(sp)
    80004192:	f426                	sd	s1,40(sp)
    80004194:	f04a                	sd	s2,32(sp)
    80004196:	ec4e                	sd	s3,24(sp)
    80004198:	e852                	sd	s4,16(sp)
    8000419a:	e456                	sd	s5,8(sp)
    8000419c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000419e:	0001d497          	auipc	s1,0x1d
    800041a2:	0d248493          	addi	s1,s1,210 # 80021270 <log>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a3c080e7          	jalr	-1476(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	37fd                	addiw	a5,a5,-1
    800041b4:	0007891b          	sext.w	s2,a5
    800041b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	efb9                	bnez	a5,8000421a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041be:	06091663          	bnez	s2,8000422a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	0ae48493          	addi	s1,s1,174 # 80021270 <log>
    800041ca:	4785                	li	a5,1
    800041cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ac8080e7          	jalr	-1336(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041d8:	54dc                	lw	a5,44(s1)
    800041da:	06f04763          	bgtz	a5,80004248 <end_op+0xbc>
    acquire(&log.lock);
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	09248493          	addi	s1,s1,146 # 80021270 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	9fc080e7          	jalr	-1540(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	062080e7          	jalr	98(ra) # 80002258 <wakeup>
    release(&log.lock);
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a98080e7          	jalr	-1384(ra) # 80000c98 <release>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    panic("log.committing");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	41e50513          	addi	a0,a0,1054 # 80008638 <syscalls+0x1f0>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	31c080e7          	jalr	796(ra) # 8000053e <panic>
    wakeup(&log);
    8000422a:	0001d497          	auipc	s1,0x1d
    8000422e:	04648493          	addi	s1,s1,70 # 80021270 <log>
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	024080e7          	jalr	36(ra) # 80002258 <wakeup>
  release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
  if(do_commit){
    80004246:	b7c9                	j	80004208 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004248:	0001da97          	auipc	s5,0x1d
    8000424c:	058a8a93          	addi	s5,s5,88 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004250:	0001da17          	auipc	s4,0x1d
    80004254:	020a0a13          	addi	s4,s4,32 # 80021270 <log>
    80004258:	018a2583          	lw	a1,24(s4)
    8000425c:	012585bb          	addw	a1,a1,s2
    80004260:	2585                	addiw	a1,a1,1
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cd2080e7          	jalr	-814(ra) # 80002f38 <bread>
    8000426e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004270:	000aa583          	lw	a1,0(s5)
    80004274:	028a2503          	lw	a0,40(s4)
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	cc0080e7          	jalr	-832(ra) # 80002f38 <bread>
    80004280:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004282:	40000613          	li	a2,1024
    80004286:	05850593          	addi	a1,a0,88
    8000428a:	05848513          	addi	a0,s1,88
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ab2080e7          	jalr	-1358(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	d92080e7          	jalr	-622(ra) # 8000302a <bwrite>
    brelse(from);
    800042a0:	854e                	mv	a0,s3
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	dc6080e7          	jalr	-570(ra) # 80003068 <brelse>
    brelse(to);
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	dbc080e7          	jalr	-580(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	2905                	addiw	s2,s2,1
    800042b6:	0a91                	addi	s5,s5,4
    800042b8:	02ca2783          	lw	a5,44(s4)
    800042bc:	f8f94ee3          	blt	s2,a5,80004258 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c6a080e7          	jalr	-918(ra) # 80003f2a <write_head>
    install_trans(0); // Now install writes to home locations
    800042c8:	4501                	li	a0,0
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	cda080e7          	jalr	-806(ra) # 80003fa4 <install_trans>
    log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	fc07a523          	sw	zero,-54(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c50080e7          	jalr	-944(ra) # 80003f2a <write_head>
    800042e2:	bdf5                	j	800041de <end_op+0x52>

00000000800042e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
    800042f0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042f2:	0001d917          	auipc	s2,0x1d
    800042f6:	f7e90913          	addi	s2,s2,-130 # 80021270 <log>
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	8e8080e7          	jalr	-1816(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004304:	02c92603          	lw	a2,44(s2)
    80004308:	47f5                	li	a5,29
    8000430a:	06c7c563          	blt	a5,a2,80004374 <log_write+0x90>
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	f7e7a783          	lw	a5,-130(a5) # 8002128c <log+0x1c>
    80004316:	37fd                	addiw	a5,a5,-1
    80004318:	04f65e63          	bge	a2,a5,80004374 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	f747a783          	lw	a5,-140(a5) # 80021290 <log+0x20>
    80004324:	06f05063          	blez	a5,80004384 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004328:	4781                	li	a5,0
    8000432a:	06c05563          	blez	a2,80004394 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000432e:	44cc                	lw	a1,12(s1)
    80004330:	0001d717          	auipc	a4,0x1d
    80004334:	f7070713          	addi	a4,a4,-144 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004338:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433a:	4314                	lw	a3,0(a4)
    8000433c:	04b68c63          	beq	a3,a1,80004394 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004340:	2785                	addiw	a5,a5,1
    80004342:	0711                	addi	a4,a4,4
    80004344:	fef61be3          	bne	a2,a5,8000433a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004348:	0621                	addi	a2,a2,8
    8000434a:	060a                	slli	a2,a2,0x2
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	f2478793          	addi	a5,a5,-220 # 80021270 <log>
    80004354:	963e                	add	a2,a2,a5
    80004356:	44dc                	lw	a5,12(s1)
    80004358:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	daa080e7          	jalr	-598(ra) # 80003106 <bpin>
    log.lh.n++;
    80004364:	0001d717          	auipc	a4,0x1d
    80004368:	f0c70713          	addi	a4,a4,-244 # 80021270 <log>
    8000436c:	575c                	lw	a5,44(a4)
    8000436e:	2785                	addiw	a5,a5,1
    80004370:	d75c                	sw	a5,44(a4)
    80004372:	a835                	j	800043ae <log_write+0xca>
    panic("too big a transaction");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	2d450513          	addi	a0,a0,724 # 80008648 <syscalls+0x200>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004384:	00004517          	auipc	a0,0x4
    80004388:	2dc50513          	addi	a0,a0,732 # 80008660 <syscalls+0x218>
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004394:	00878713          	addi	a4,a5,8
    80004398:	00271693          	slli	a3,a4,0x2
    8000439c:	0001d717          	auipc	a4,0x1d
    800043a0:	ed470713          	addi	a4,a4,-300 # 80021270 <log>
    800043a4:	9736                	add	a4,a4,a3
    800043a6:	44d4                	lw	a3,12(s1)
    800043a8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043aa:	faf608e3          	beq	a2,a5,8000435a <log_write+0x76>
  }
  release(&log.lock);
    800043ae:	0001d517          	auipc	a0,0x1d
    800043b2:	ec250513          	addi	a0,a0,-318 # 80021270 <log>
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
    800043d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043da:	00004597          	auipc	a1,0x4
    800043de:	2a658593          	addi	a1,a1,678 # 80008680 <syscalls+0x238>
    800043e2:	0521                	addi	a0,a0,8
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	770080e7          	jalr	1904(ra) # 80000b54 <initlock>
  lk->name = name;
    800043ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f4:	0204a423          	sw	zero,40(s1)
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	64a2                	ld	s1,8(sp)
    800043fe:	6902                	ld	s2,0(sp)
    80004400:	6105                	addi	sp,sp,32
    80004402:	8082                	ret

0000000080004404 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004404:	1101                	addi	sp,sp,-32
    80004406:	ec06                	sd	ra,24(sp)
    80004408:	e822                	sd	s0,16(sp)
    8000440a:	e426                	sd	s1,8(sp)
    8000440c:	e04a                	sd	s2,0(sp)
    8000440e:	1000                	addi	s0,sp,32
    80004410:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004412:	00850913          	addi	s2,a0,8
    80004416:	854a                	mv	a0,s2
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7cc080e7          	jalr	1996(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004420:	409c                	lw	a5,0(s1)
    80004422:	cb89                	beqz	a5,80004434 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004424:	85ca                	mv	a1,s2
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	ca4080e7          	jalr	-860(ra) # 800020cc <sleep>
  while (lk->locked) {
    80004430:	409c                	lw	a5,0(s1)
    80004432:	fbed                	bnez	a5,80004424 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004434:	4785                	li	a5,1
    80004436:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	578080e7          	jalr	1400(ra) # 800019b0 <myproc>
    80004440:	591c                	lw	a5,48(a0)
    80004442:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	852080e7          	jalr	-1966(ra) # 80000c98 <release>
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000445a:	1101                	addi	sp,sp,-32
    8000445c:	ec06                	sd	ra,24(sp)
    8000445e:	e822                	sd	s0,16(sp)
    80004460:	e426                	sd	s1,8(sp)
    80004462:	e04a                	sd	s2,0(sp)
    80004464:	1000                	addi	s0,sp,32
    80004466:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004468:	00850913          	addi	s2,a0,8
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004476:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000447a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	dd8080e7          	jalr	-552(ra) # 80002258 <wakeup>
  release(&lk->lk);
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	80e080e7          	jalr	-2034(ra) # 80000c98 <release>
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000449e:	7179                	addi	sp,sp,-48
    800044a0:	f406                	sd	ra,40(sp)
    800044a2:	f022                	sd	s0,32(sp)
    800044a4:	ec26                	sd	s1,24(sp)
    800044a6:	e84a                	sd	s2,16(sp)
    800044a8:	e44e                	sd	s3,8(sp)
    800044aa:	1800                	addi	s0,sp,48
    800044ac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ae:	00850913          	addi	s2,a0,8
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044bc:	409c                	lw	a5,0(s1)
    800044be:	ef99                	bnez	a5,800044dc <holdingsleep+0x3e>
    800044c0:	4481                	li	s1,0
  release(&lk->lk);
    800044c2:	854a                	mv	a0,s2
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7d4080e7          	jalr	2004(ra) # 80000c98 <release>
  return r;
}
    800044cc:	8526                	mv	a0,s1
    800044ce:	70a2                	ld	ra,40(sp)
    800044d0:	7402                	ld	s0,32(sp)
    800044d2:	64e2                	ld	s1,24(sp)
    800044d4:	6942                	ld	s2,16(sp)
    800044d6:	69a2                	ld	s3,8(sp)
    800044d8:	6145                	addi	sp,sp,48
    800044da:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044dc:	0284a983          	lw	s3,40(s1)
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	4d0080e7          	jalr	1232(ra) # 800019b0 <myproc>
    800044e8:	5904                	lw	s1,48(a0)
    800044ea:	413484b3          	sub	s1,s1,s3
    800044ee:	0014b493          	seqz	s1,s1
    800044f2:	bfc1                	j	800044c2 <holdingsleep+0x24>

00000000800044f4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044f4:	1141                	addi	sp,sp,-16
    800044f6:	e406                	sd	ra,8(sp)
    800044f8:	e022                	sd	s0,0(sp)
    800044fa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044fc:	00004597          	auipc	a1,0x4
    80004500:	19458593          	addi	a1,a1,404 # 80008690 <syscalls+0x248>
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	eb450513          	addi	a0,a0,-332 # 800213b8 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	648080e7          	jalr	1608(ra) # 80000b54 <initlock>
}
    80004514:	60a2                	ld	ra,8(sp)
    80004516:	6402                	ld	s0,0(sp)
    80004518:	0141                	addi	sp,sp,16
    8000451a:	8082                	ret

000000008000451c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004526:	0001d517          	auipc	a0,0x1d
    8000452a:	e9250513          	addi	a0,a0,-366 # 800213b8 <ftable>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	0001d497          	auipc	s1,0x1d
    8000453a:	e9a48493          	addi	s1,s1,-358 # 800213d0 <ftable+0x18>
    8000453e:	0001e717          	auipc	a4,0x1e
    80004542:	e3270713          	addi	a4,a4,-462 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004546:	40dc                	lw	a5,4(s1)
    80004548:	cf99                	beqz	a5,80004566 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000454a:	02848493          	addi	s1,s1,40
    8000454e:	fee49ce3          	bne	s1,a4,80004546 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	e6650513          	addi	a0,a0,-410 # 800213b8 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	73e080e7          	jalr	1854(ra) # 80000c98 <release>
  return 0;
    80004562:	4481                	li	s1,0
    80004564:	a819                	j	8000457a <filealloc+0x5e>
      f->ref = 1;
    80004566:	4785                	li	a5,1
    80004568:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	e4e50513          	addi	a0,a0,-434 # 800213b8 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	726080e7          	jalr	1830(ra) # 80000c98 <release>
}
    8000457a:	8526                	mv	a0,s1
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6105                	addi	sp,sp,32
    80004584:	8082                	ret

0000000080004586 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	1000                	addi	s0,sp,32
    80004590:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004592:	0001d517          	auipc	a0,0x1d
    80004596:	e2650513          	addi	a0,a0,-474 # 800213b8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	64a080e7          	jalr	1610(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045a2:	40dc                	lw	a5,4(s1)
    800045a4:	02f05263          	blez	a5,800045c8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045a8:	2785                	addiw	a5,a5,1
    800045aa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	e0c50513          	addi	a0,a0,-500 # 800213b8 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
  return f;
}
    800045bc:	8526                	mv	a0,s1
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret
    panic("filedup");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	0d050513          	addi	a0,a0,208 # 80008698 <syscalls+0x250>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>

00000000800045d8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045d8:	7139                	addi	sp,sp,-64
    800045da:	fc06                	sd	ra,56(sp)
    800045dc:	f822                	sd	s0,48(sp)
    800045de:	f426                	sd	s1,40(sp)
    800045e0:	f04a                	sd	s2,32(sp)
    800045e2:	ec4e                	sd	s3,24(sp)
    800045e4:	e852                	sd	s4,16(sp)
    800045e6:	e456                	sd	s5,8(sp)
    800045e8:	0080                	addi	s0,sp,64
    800045ea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ec:	0001d517          	auipc	a0,0x1d
    800045f0:	dcc50513          	addi	a0,a0,-564 # 800213b8 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045fc:	40dc                	lw	a5,4(s1)
    800045fe:	06f05163          	blez	a5,80004660 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004602:	37fd                	addiw	a5,a5,-1
    80004604:	0007871b          	sext.w	a4,a5
    80004608:	c0dc                	sw	a5,4(s1)
    8000460a:	06e04363          	bgtz	a4,80004670 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000460e:	0004a903          	lw	s2,0(s1)
    80004612:	0094ca83          	lbu	s5,9(s1)
    80004616:	0104ba03          	ld	s4,16(s1)
    8000461a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000461e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004622:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004626:	0001d517          	auipc	a0,0x1d
    8000462a:	d9250513          	addi	a0,a0,-622 # 800213b8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004636:	4785                	li	a5,1
    80004638:	04f90d63          	beq	s2,a5,80004692 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000463c:	3979                	addiw	s2,s2,-2
    8000463e:	4785                	li	a5,1
    80004640:	0527e063          	bltu	a5,s2,80004680 <fileclose+0xa8>
    begin_op();
    80004644:	00000097          	auipc	ra,0x0
    80004648:	ac8080e7          	jalr	-1336(ra) # 8000410c <begin_op>
    iput(ff.ip);
    8000464c:	854e                	mv	a0,s3
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	2a6080e7          	jalr	678(ra) # 800038f4 <iput>
    end_op();
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	b36080e7          	jalr	-1226(ra) # 8000418c <end_op>
    8000465e:	a00d                	j	80004680 <fileclose+0xa8>
    panic("fileclose");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	04050513          	addi	a0,a0,64 # 800086a0 <syscalls+0x258>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	d4850513          	addi	a0,a0,-696 # 800213b8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	620080e7          	jalr	1568(ra) # 80000c98 <release>
  }
}
    80004680:	70e2                	ld	ra,56(sp)
    80004682:	7442                	ld	s0,48(sp)
    80004684:	74a2                	ld	s1,40(sp)
    80004686:	7902                	ld	s2,32(sp)
    80004688:	69e2                	ld	s3,24(sp)
    8000468a:	6a42                	ld	s4,16(sp)
    8000468c:	6aa2                	ld	s5,8(sp)
    8000468e:	6121                	addi	sp,sp,64
    80004690:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004692:	85d6                	mv	a1,s5
    80004694:	8552                	mv	a0,s4
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	34c080e7          	jalr	844(ra) # 800049e2 <pipeclose>
    8000469e:	b7cd                	j	80004680 <fileclose+0xa8>

00000000800046a0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a0:	715d                	addi	sp,sp,-80
    800046a2:	e486                	sd	ra,72(sp)
    800046a4:	e0a2                	sd	s0,64(sp)
    800046a6:	fc26                	sd	s1,56(sp)
    800046a8:	f84a                	sd	s2,48(sp)
    800046aa:	f44e                	sd	s3,40(sp)
    800046ac:	0880                	addi	s0,sp,80
    800046ae:	84aa                	mv	s1,a0
    800046b0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b2:	ffffd097          	auipc	ra,0xffffd
    800046b6:	2fe080e7          	jalr	766(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	37f9                	addiw	a5,a5,-2
    800046be:	4705                	li	a4,1
    800046c0:	04f76763          	bltu	a4,a5,8000470e <filestat+0x6e>
    800046c4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046c6:	6c88                	ld	a0,24(s1)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	072080e7          	jalr	114(ra) # 8000373a <ilock>
    stati(f->ip, &st);
    800046d0:	fb840593          	addi	a1,s0,-72
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	2ee080e7          	jalr	750(ra) # 800039c4 <stati>
    iunlock(f->ip);
    800046de:	6c88                	ld	a0,24(s1)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	11c080e7          	jalr	284(ra) # 800037fc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046e8:	46e1                	li	a3,24
    800046ea:	fb840613          	addi	a2,s0,-72
    800046ee:	85ce                	mv	a1,s3
    800046f0:	05093503          	ld	a0,80(s2)
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	f7e080e7          	jalr	-130(ra) # 80001672 <copyout>
    800046fc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004700:	60a6                	ld	ra,72(sp)
    80004702:	6406                	ld	s0,64(sp)
    80004704:	74e2                	ld	s1,56(sp)
    80004706:	7942                	ld	s2,48(sp)
    80004708:	79a2                	ld	s3,40(sp)
    8000470a:	6161                	addi	sp,sp,80
    8000470c:	8082                	ret
  return -1;
    8000470e:	557d                	li	a0,-1
    80004710:	bfc5                	j	80004700 <filestat+0x60>

0000000080004712 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004712:	7179                	addi	sp,sp,-48
    80004714:	f406                	sd	ra,40(sp)
    80004716:	f022                	sd	s0,32(sp)
    80004718:	ec26                	sd	s1,24(sp)
    8000471a:	e84a                	sd	s2,16(sp)
    8000471c:	e44e                	sd	s3,8(sp)
    8000471e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004720:	00854783          	lbu	a5,8(a0)
    80004724:	c3d5                	beqz	a5,800047c8 <fileread+0xb6>
    80004726:	84aa                	mv	s1,a0
    80004728:	89ae                	mv	s3,a1
    8000472a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000472c:	411c                	lw	a5,0(a0)
    8000472e:	4705                	li	a4,1
    80004730:	04e78963          	beq	a5,a4,80004782 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004734:	470d                	li	a4,3
    80004736:	04e78d63          	beq	a5,a4,80004790 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000473a:	4709                	li	a4,2
    8000473c:	06e79e63          	bne	a5,a4,800047b8 <fileread+0xa6>
    ilock(f->ip);
    80004740:	6d08                	ld	a0,24(a0)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	ff8080e7          	jalr	-8(ra) # 8000373a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000474a:	874a                	mv	a4,s2
    8000474c:	5094                	lw	a3,32(s1)
    8000474e:	864e                	mv	a2,s3
    80004750:	4585                	li	a1,1
    80004752:	6c88                	ld	a0,24(s1)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	29a080e7          	jalr	666(ra) # 800039ee <readi>
    8000475c:	892a                	mv	s2,a0
    8000475e:	00a05563          	blez	a0,80004768 <fileread+0x56>
      f->off += r;
    80004762:	509c                	lw	a5,32(s1)
    80004764:	9fa9                	addw	a5,a5,a0
    80004766:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	092080e7          	jalr	146(ra) # 800037fc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004772:	854a                	mv	a0,s2
    80004774:	70a2                	ld	ra,40(sp)
    80004776:	7402                	ld	s0,32(sp)
    80004778:	64e2                	ld	s1,24(sp)
    8000477a:	6942                	ld	s2,16(sp)
    8000477c:	69a2                	ld	s3,8(sp)
    8000477e:	6145                	addi	sp,sp,48
    80004780:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	3c8080e7          	jalr	968(ra) # 80004b4c <piperead>
    8000478c:	892a                	mv	s2,a0
    8000478e:	b7d5                	j	80004772 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	02d76863          	bltu	a4,a3,800047cc <fileread+0xba>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001d717          	auipc	a4,0x1d
    800047a6:	b7670713          	addi	a4,a4,-1162 # 80021318 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	639c                	ld	a5,0(a5)
    800047ae:	c38d                	beqz	a5,800047d0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	892a                	mv	s2,a0
    800047b6:	bf75                	j	80004772 <fileread+0x60>
    panic("fileread");
    800047b8:	00004517          	auipc	a0,0x4
    800047bc:	ef850513          	addi	a0,a0,-264 # 800086b0 <syscalls+0x268>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	d7e080e7          	jalr	-642(ra) # 8000053e <panic>
    return -1;
    800047c8:	597d                	li	s2,-1
    800047ca:	b765                	j	80004772 <fileread+0x60>
      return -1;
    800047cc:	597d                	li	s2,-1
    800047ce:	b755                	j	80004772 <fileread+0x60>
    800047d0:	597d                	li	s2,-1
    800047d2:	b745                	j	80004772 <fileread+0x60>

00000000800047d4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047d4:	715d                	addi	sp,sp,-80
    800047d6:	e486                	sd	ra,72(sp)
    800047d8:	e0a2                	sd	s0,64(sp)
    800047da:	fc26                	sd	s1,56(sp)
    800047dc:	f84a                	sd	s2,48(sp)
    800047de:	f44e                	sd	s3,40(sp)
    800047e0:	f052                	sd	s4,32(sp)
    800047e2:	ec56                	sd	s5,24(sp)
    800047e4:	e85a                	sd	s6,16(sp)
    800047e6:	e45e                	sd	s7,8(sp)
    800047e8:	e062                	sd	s8,0(sp)
    800047ea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ec:	00954783          	lbu	a5,9(a0)
    800047f0:	10078663          	beqz	a5,800048fc <filewrite+0x128>
    800047f4:	892a                	mv	s2,a0
    800047f6:	8aae                	mv	s5,a1
    800047f8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047fa:	411c                	lw	a5,0(a0)
    800047fc:	4705                	li	a4,1
    800047fe:	02e78263          	beq	a5,a4,80004822 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004802:	470d                	li	a4,3
    80004804:	02e78663          	beq	a5,a4,80004830 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004808:	4709                	li	a4,2
    8000480a:	0ee79163          	bne	a5,a4,800048ec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000480e:	0ac05d63          	blez	a2,800048c8 <filewrite+0xf4>
    int i = 0;
    80004812:	4981                	li	s3,0
    80004814:	6b05                	lui	s6,0x1
    80004816:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000481a:	6b85                	lui	s7,0x1
    8000481c:	c00b8b9b          	addiw	s7,s7,-1024
    80004820:	a861                	j	800048b8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004822:	6908                	ld	a0,16(a0)
    80004824:	00000097          	auipc	ra,0x0
    80004828:	22e080e7          	jalr	558(ra) # 80004a52 <pipewrite>
    8000482c:	8a2a                	mv	s4,a0
    8000482e:	a045                	j	800048ce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004830:	02451783          	lh	a5,36(a0)
    80004834:	03079693          	slli	a3,a5,0x30
    80004838:	92c1                	srli	a3,a3,0x30
    8000483a:	4725                	li	a4,9
    8000483c:	0cd76263          	bltu	a4,a3,80004900 <filewrite+0x12c>
    80004840:	0792                	slli	a5,a5,0x4
    80004842:	0001d717          	auipc	a4,0x1d
    80004846:	ad670713          	addi	a4,a4,-1322 # 80021318 <devsw>
    8000484a:	97ba                	add	a5,a5,a4
    8000484c:	679c                	ld	a5,8(a5)
    8000484e:	cbdd                	beqz	a5,80004904 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004850:	4505                	li	a0,1
    80004852:	9782                	jalr	a5
    80004854:	8a2a                	mv	s4,a0
    80004856:	a8a5                	j	800048ce <filewrite+0xfa>
    80004858:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	8b0080e7          	jalr	-1872(ra) # 8000410c <begin_op>
      ilock(f->ip);
    80004864:	01893503          	ld	a0,24(s2)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	ed2080e7          	jalr	-302(ra) # 8000373a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004870:	8762                	mv	a4,s8
    80004872:	02092683          	lw	a3,32(s2)
    80004876:	01598633          	add	a2,s3,s5
    8000487a:	4585                	li	a1,1
    8000487c:	01893503          	ld	a0,24(s2)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	266080e7          	jalr	614(ra) # 80003ae6 <writei>
    80004888:	84aa                	mv	s1,a0
    8000488a:	00a05763          	blez	a0,80004898 <filewrite+0xc4>
        f->off += r;
    8000488e:	02092783          	lw	a5,32(s2)
    80004892:	9fa9                	addw	a5,a5,a0
    80004894:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004898:	01893503          	ld	a0,24(s2)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	f60080e7          	jalr	-160(ra) # 800037fc <iunlock>
      end_op();
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	8e8080e7          	jalr	-1816(ra) # 8000418c <end_op>

      if(r != n1){
    800048ac:	009c1f63          	bne	s8,s1,800048ca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048b0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b4:	0149db63          	bge	s3,s4,800048ca <filewrite+0xf6>
      int n1 = n - i;
    800048b8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048bc:	84be                	mv	s1,a5
    800048be:	2781                	sext.w	a5,a5
    800048c0:	f8fb5ce3          	bge	s6,a5,80004858 <filewrite+0x84>
    800048c4:	84de                	mv	s1,s7
    800048c6:	bf49                	j	80004858 <filewrite+0x84>
    int i = 0;
    800048c8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048ca:	013a1f63          	bne	s4,s3,800048e8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ce:	8552                	mv	a0,s4
    800048d0:	60a6                	ld	ra,72(sp)
    800048d2:	6406                	ld	s0,64(sp)
    800048d4:	74e2                	ld	s1,56(sp)
    800048d6:	7942                	ld	s2,48(sp)
    800048d8:	79a2                	ld	s3,40(sp)
    800048da:	7a02                	ld	s4,32(sp)
    800048dc:	6ae2                	ld	s5,24(sp)
    800048de:	6b42                	ld	s6,16(sp)
    800048e0:	6ba2                	ld	s7,8(sp)
    800048e2:	6c02                	ld	s8,0(sp)
    800048e4:	6161                	addi	sp,sp,80
    800048e6:	8082                	ret
    ret = (i == n ? n : -1);
    800048e8:	5a7d                	li	s4,-1
    800048ea:	b7d5                	j	800048ce <filewrite+0xfa>
    panic("filewrite");
    800048ec:	00004517          	auipc	a0,0x4
    800048f0:	dd450513          	addi	a0,a0,-556 # 800086c0 <syscalls+0x278>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>
    return -1;
    800048fc:	5a7d                	li	s4,-1
    800048fe:	bfc1                	j	800048ce <filewrite+0xfa>
      return -1;
    80004900:	5a7d                	li	s4,-1
    80004902:	b7f1                	j	800048ce <filewrite+0xfa>
    80004904:	5a7d                	li	s4,-1
    80004906:	b7e1                	j	800048ce <filewrite+0xfa>

0000000080004908 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004908:	7179                	addi	sp,sp,-48
    8000490a:	f406                	sd	ra,40(sp)
    8000490c:	f022                	sd	s0,32(sp)
    8000490e:	ec26                	sd	s1,24(sp)
    80004910:	e84a                	sd	s2,16(sp)
    80004912:	e44e                	sd	s3,8(sp)
    80004914:	e052                	sd	s4,0(sp)
    80004916:	1800                	addi	s0,sp,48
    80004918:	84aa                	mv	s1,a0
    8000491a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000491c:	0005b023          	sd	zero,0(a1)
    80004920:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004924:	00000097          	auipc	ra,0x0
    80004928:	bf8080e7          	jalr	-1032(ra) # 8000451c <filealloc>
    8000492c:	e088                	sd	a0,0(s1)
    8000492e:	c551                	beqz	a0,800049ba <pipealloc+0xb2>
    80004930:	00000097          	auipc	ra,0x0
    80004934:	bec080e7          	jalr	-1044(ra) # 8000451c <filealloc>
    80004938:	00aa3023          	sd	a0,0(s4)
    8000493c:	c92d                	beqz	a0,800049ae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	1b6080e7          	jalr	438(ra) # 80000af4 <kalloc>
    80004946:	892a                	mv	s2,a0
    80004948:	c125                	beqz	a0,800049a8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000494a:	4985                	li	s3,1
    8000494c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004950:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004954:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004958:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000495c:	00004597          	auipc	a1,0x4
    80004960:	d7458593          	addi	a1,a1,-652 # 800086d0 <syscalls+0x288>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	1f0080e7          	jalr	496(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000496c:	609c                	ld	a5,0(s1)
    8000496e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004972:	609c                	ld	a5,0(s1)
    80004974:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004978:	609c                	ld	a5,0(s1)
    8000497a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000497e:	609c                	ld	a5,0(s1)
    80004980:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004984:	000a3783          	ld	a5,0(s4)
    80004988:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000498c:	000a3783          	ld	a5,0(s4)
    80004990:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004994:	000a3783          	ld	a5,0(s4)
    80004998:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000499c:	000a3783          	ld	a5,0(s4)
    800049a0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a4:	4501                	li	a0,0
    800049a6:	a025                	j	800049ce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049a8:	6088                	ld	a0,0(s1)
    800049aa:	e501                	bnez	a0,800049b2 <pipealloc+0xaa>
    800049ac:	a039                	j	800049ba <pipealloc+0xb2>
    800049ae:	6088                	ld	a0,0(s1)
    800049b0:	c51d                	beqz	a0,800049de <pipealloc+0xd6>
    fileclose(*f0);
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	c26080e7          	jalr	-986(ra) # 800045d8 <fileclose>
  if(*f1)
    800049ba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049be:	557d                	li	a0,-1
  if(*f1)
    800049c0:	c799                	beqz	a5,800049ce <pipealloc+0xc6>
    fileclose(*f1);
    800049c2:	853e                	mv	a0,a5
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	c14080e7          	jalr	-1004(ra) # 800045d8 <fileclose>
  return -1;
    800049cc:	557d                	li	a0,-1
}
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6942                	ld	s2,16(sp)
    800049d6:	69a2                	ld	s3,8(sp)
    800049d8:	6a02                	ld	s4,0(sp)
    800049da:	6145                	addi	sp,sp,48
    800049dc:	8082                	ret
  return -1;
    800049de:	557d                	li	a0,-1
    800049e0:	b7fd                	j	800049ce <pipealloc+0xc6>

00000000800049e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	e04a                	sd	s2,0(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
    800049f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
  if(writable){
    800049fa:	02090d63          	beqz	s2,80004a34 <pipeclose+0x52>
    pi->writeopen = 0;
    800049fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a02:	21848513          	addi	a0,s1,536
    80004a06:	ffffe097          	auipc	ra,0xffffe
    80004a0a:	852080e7          	jalr	-1966(ra) # 80002258 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a0e:	2204b783          	ld	a5,544(s1)
    80004a12:	eb95                	bnez	a5,80004a46 <pipeclose+0x64>
    release(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a1e:	8526                	mv	a0,s1
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	fd8080e7          	jalr	-40(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a28:	60e2                	ld	ra,24(sp)
    80004a2a:	6442                	ld	s0,16(sp)
    80004a2c:	64a2                	ld	s1,8(sp)
    80004a2e:	6902                	ld	s2,0(sp)
    80004a30:	6105                	addi	sp,sp,32
    80004a32:	8082                	ret
    pi->readopen = 0;
    80004a34:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a38:	21c48513          	addi	a0,s1,540
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	81c080e7          	jalr	-2020(ra) # 80002258 <wakeup>
    80004a44:	b7e9                	j	80004a0e <pipeclose+0x2c>
    release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
}
    80004a50:	bfe1                	j	80004a28 <pipeclose+0x46>

0000000080004a52 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a52:	7159                	addi	sp,sp,-112
    80004a54:	f486                	sd	ra,104(sp)
    80004a56:	f0a2                	sd	s0,96(sp)
    80004a58:	eca6                	sd	s1,88(sp)
    80004a5a:	e8ca                	sd	s2,80(sp)
    80004a5c:	e4ce                	sd	s3,72(sp)
    80004a5e:	e0d2                	sd	s4,64(sp)
    80004a60:	fc56                	sd	s5,56(sp)
    80004a62:	f85a                	sd	s6,48(sp)
    80004a64:	f45e                	sd	s7,40(sp)
    80004a66:	f062                	sd	s8,32(sp)
    80004a68:	ec66                	sd	s9,24(sp)
    80004a6a:	1880                	addi	s0,sp,112
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	8aae                	mv	s5,a1
    80004a70:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	f3e080e7          	jalr	-194(ra) # 800019b0 <myproc>
    80004a7a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
  while(i < n){
    80004a86:	0d405163          	blez	s4,80004b48 <pipewrite+0xf6>
    80004a8a:	8ba6                	mv	s7,s1
  int i = 0;
    80004a8c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a8e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a90:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a94:	21c48c13          	addi	s8,s1,540
    80004a98:	a08d                	j	80004afa <pipewrite+0xa8>
      release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	1fc080e7          	jalr	508(ra) # 80000c98 <release>
      return -1;
    80004aa4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aa6:	854a                	mv	a0,s2
    80004aa8:	70a6                	ld	ra,104(sp)
    80004aaa:	7406                	ld	s0,96(sp)
    80004aac:	64e6                	ld	s1,88(sp)
    80004aae:	6946                	ld	s2,80(sp)
    80004ab0:	69a6                	ld	s3,72(sp)
    80004ab2:	6a06                	ld	s4,64(sp)
    80004ab4:	7ae2                	ld	s5,56(sp)
    80004ab6:	7b42                	ld	s6,48(sp)
    80004ab8:	7ba2                	ld	s7,40(sp)
    80004aba:	7c02                	ld	s8,32(sp)
    80004abc:	6ce2                	ld	s9,24(sp)
    80004abe:	6165                	addi	sp,sp,112
    80004ac0:	8082                	ret
      wakeup(&pi->nread);
    80004ac2:	8566                	mv	a0,s9
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	794080e7          	jalr	1940(ra) # 80002258 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	85de                	mv	a1,s7
    80004ace:	8562                	mv	a0,s8
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	5fc080e7          	jalr	1532(ra) # 800020cc <sleep>
    80004ad8:	a839                	j	80004af6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ada:	21c4a783          	lw	a5,540(s1)
    80004ade:	0017871b          	addiw	a4,a5,1
    80004ae2:	20e4ae23          	sw	a4,540(s1)
    80004ae6:	1ff7f793          	andi	a5,a5,511
    80004aea:	97a6                	add	a5,a5,s1
    80004aec:	f9f44703          	lbu	a4,-97(s0)
    80004af0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004af6:	03495d63          	bge	s2,s4,80004b30 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004afa:	2204a783          	lw	a5,544(s1)
    80004afe:	dfd1                	beqz	a5,80004a9a <pipewrite+0x48>
    80004b00:	0289a783          	lw	a5,40(s3)
    80004b04:	fbd9                	bnez	a5,80004a9a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b06:	2184a783          	lw	a5,536(s1)
    80004b0a:	21c4a703          	lw	a4,540(s1)
    80004b0e:	2007879b          	addiw	a5,a5,512
    80004b12:	faf708e3          	beq	a4,a5,80004ac2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b16:	4685                	li	a3,1
    80004b18:	01590633          	add	a2,s2,s5
    80004b1c:	f9f40593          	addi	a1,s0,-97
    80004b20:	0509b503          	ld	a0,80(s3)
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	bda080e7          	jalr	-1062(ra) # 800016fe <copyin>
    80004b2c:	fb6517e3          	bne	a0,s6,80004ada <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b30:	21848513          	addi	a0,s1,536
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	724080e7          	jalr	1828(ra) # 80002258 <wakeup>
  release(&pi->lock);
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	15a080e7          	jalr	346(ra) # 80000c98 <release>
  return i;
    80004b46:	b785                	j	80004aa6 <pipewrite+0x54>
  int i = 0;
    80004b48:	4901                	li	s2,0
    80004b4a:	b7dd                	j	80004b30 <pipewrite+0xde>

0000000080004b4c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b4c:	715d                	addi	sp,sp,-80
    80004b4e:	e486                	sd	ra,72(sp)
    80004b50:	e0a2                	sd	s0,64(sp)
    80004b52:	fc26                	sd	s1,56(sp)
    80004b54:	f84a                	sd	s2,48(sp)
    80004b56:	f44e                	sd	s3,40(sp)
    80004b58:	f052                	sd	s4,32(sp)
    80004b5a:	ec56                	sd	s5,24(sp)
    80004b5c:	e85a                	sd	s6,16(sp)
    80004b5e:	0880                	addi	s0,sp,80
    80004b60:	84aa                	mv	s1,a0
    80004b62:	892e                	mv	s2,a1
    80004b64:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	e4a080e7          	jalr	-438(ra) # 800019b0 <myproc>
    80004b6e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b70:	8b26                	mv	s6,s1
    80004b72:	8526                	mv	a0,s1
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	070080e7          	jalr	112(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b7c:	2184a703          	lw	a4,536(s1)
    80004b80:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b84:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b88:	02f71463          	bne	a4,a5,80004bb0 <piperead+0x64>
    80004b8c:	2244a783          	lw	a5,548(s1)
    80004b90:	c385                	beqz	a5,80004bb0 <piperead+0x64>
    if(pr->killed){
    80004b92:	028a2783          	lw	a5,40(s4)
    80004b96:	ebc1                	bnez	a5,80004c26 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b98:	85da                	mv	a1,s6
    80004b9a:	854e                	mv	a0,s3
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	530080e7          	jalr	1328(ra) # 800020cc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba4:	2184a703          	lw	a4,536(s1)
    80004ba8:	21c4a783          	lw	a5,540(s1)
    80004bac:	fef700e3          	beq	a4,a5,80004b8c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb0:	09505263          	blez	s5,80004c34 <piperead+0xe8>
    80004bb4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bb6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bb8:	2184a783          	lw	a5,536(s1)
    80004bbc:	21c4a703          	lw	a4,540(s1)
    80004bc0:	02f70d63          	beq	a4,a5,80004bfa <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bc4:	0017871b          	addiw	a4,a5,1
    80004bc8:	20e4ac23          	sw	a4,536(s1)
    80004bcc:	1ff7f793          	andi	a5,a5,511
    80004bd0:	97a6                	add	a5,a5,s1
    80004bd2:	0187c783          	lbu	a5,24(a5)
    80004bd6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bda:	4685                	li	a3,1
    80004bdc:	fbf40613          	addi	a2,s0,-65
    80004be0:	85ca                	mv	a1,s2
    80004be2:	050a3503          	ld	a0,80(s4)
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	a8c080e7          	jalr	-1396(ra) # 80001672 <copyout>
    80004bee:	01650663          	beq	a0,s6,80004bfa <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf2:	2985                	addiw	s3,s3,1
    80004bf4:	0905                	addi	s2,s2,1
    80004bf6:	fd3a91e3          	bne	s5,s3,80004bb8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bfa:	21c48513          	addi	a0,s1,540
    80004bfe:	ffffd097          	auipc	ra,0xffffd
    80004c02:	65a080e7          	jalr	1626(ra) # 80002258 <wakeup>
  release(&pi->lock);
    80004c06:	8526                	mv	a0,s1
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	090080e7          	jalr	144(ra) # 80000c98 <release>
  return i;
}
    80004c10:	854e                	mv	a0,s3
    80004c12:	60a6                	ld	ra,72(sp)
    80004c14:	6406                	ld	s0,64(sp)
    80004c16:	74e2                	ld	s1,56(sp)
    80004c18:	7942                	ld	s2,48(sp)
    80004c1a:	79a2                	ld	s3,40(sp)
    80004c1c:	7a02                	ld	s4,32(sp)
    80004c1e:	6ae2                	ld	s5,24(sp)
    80004c20:	6b42                	ld	s6,16(sp)
    80004c22:	6161                	addi	sp,sp,80
    80004c24:	8082                	ret
      release(&pi->lock);
    80004c26:	8526                	mv	a0,s1
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	070080e7          	jalr	112(ra) # 80000c98 <release>
      return -1;
    80004c30:	59fd                	li	s3,-1
    80004c32:	bff9                	j	80004c10 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c34:	4981                	li	s3,0
    80004c36:	b7d1                	j	80004bfa <piperead+0xae>

0000000080004c38 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c38:	df010113          	addi	sp,sp,-528
    80004c3c:	20113423          	sd	ra,520(sp)
    80004c40:	20813023          	sd	s0,512(sp)
    80004c44:	ffa6                	sd	s1,504(sp)
    80004c46:	fbca                	sd	s2,496(sp)
    80004c48:	f7ce                	sd	s3,488(sp)
    80004c4a:	f3d2                	sd	s4,480(sp)
    80004c4c:	efd6                	sd	s5,472(sp)
    80004c4e:	ebda                	sd	s6,464(sp)
    80004c50:	e7de                	sd	s7,456(sp)
    80004c52:	e3e2                	sd	s8,448(sp)
    80004c54:	ff66                	sd	s9,440(sp)
    80004c56:	fb6a                	sd	s10,432(sp)
    80004c58:	f76e                	sd	s11,424(sp)
    80004c5a:	0c00                	addi	s0,sp,528
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	dea43c23          	sd	a0,-520(s0)
    80004c62:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	d4a080e7          	jalr	-694(ra) # 800019b0 <myproc>
    80004c6e:	892a                	mv	s2,a0

  begin_op();
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	49c080e7          	jalr	1180(ra) # 8000410c <begin_op>

  if((ip = namei(path)) == 0){
    80004c78:	8526                	mv	a0,s1
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	276080e7          	jalr	630(ra) # 80003ef0 <namei>
    80004c82:	c92d                	beqz	a0,80004cf4 <exec+0xbc>
    80004c84:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	ab4080e7          	jalr	-1356(ra) # 8000373a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c8e:	04000713          	li	a4,64
    80004c92:	4681                	li	a3,0
    80004c94:	e5040613          	addi	a2,s0,-432
    80004c98:	4581                	li	a1,0
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	d52080e7          	jalr	-686(ra) # 800039ee <readi>
    80004ca4:	04000793          	li	a5,64
    80004ca8:	00f51a63          	bne	a0,a5,80004cbc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cac:	e5042703          	lw	a4,-432(s0)
    80004cb0:	464c47b7          	lui	a5,0x464c4
    80004cb4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cb8:	04f70463          	beq	a4,a5,80004d00 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	cde080e7          	jalr	-802(ra) # 8000399c <iunlockput>
    end_op();
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	4c6080e7          	jalr	1222(ra) # 8000418c <end_op>
  }
  return -1;
    80004cce:	557d                	li	a0,-1
}
    80004cd0:	20813083          	ld	ra,520(sp)
    80004cd4:	20013403          	ld	s0,512(sp)
    80004cd8:	74fe                	ld	s1,504(sp)
    80004cda:	795e                	ld	s2,496(sp)
    80004cdc:	79be                	ld	s3,488(sp)
    80004cde:	7a1e                	ld	s4,480(sp)
    80004ce0:	6afe                	ld	s5,472(sp)
    80004ce2:	6b5e                	ld	s6,464(sp)
    80004ce4:	6bbe                	ld	s7,456(sp)
    80004ce6:	6c1e                	ld	s8,448(sp)
    80004ce8:	7cfa                	ld	s9,440(sp)
    80004cea:	7d5a                	ld	s10,432(sp)
    80004cec:	7dba                	ld	s11,424(sp)
    80004cee:	21010113          	addi	sp,sp,528
    80004cf2:	8082                	ret
    end_op();
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	498080e7          	jalr	1176(ra) # 8000418c <end_op>
    return -1;
    80004cfc:	557d                	li	a0,-1
    80004cfe:	bfc9                	j	80004cd0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d00:	854a                	mv	a0,s2
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	d72080e7          	jalr	-654(ra) # 80001a74 <proc_pagetable>
    80004d0a:	8baa                	mv	s7,a0
    80004d0c:	d945                	beqz	a0,80004cbc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d0e:	e7042983          	lw	s3,-400(s0)
    80004d12:	e8845783          	lhu	a5,-376(s0)
    80004d16:	c7ad                	beqz	a5,80004d80 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d18:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d1c:	6c85                	lui	s9,0x1
    80004d1e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d22:	def43823          	sd	a5,-528(s0)
    80004d26:	a42d                	j	80004f50 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d28:	00004517          	auipc	a0,0x4
    80004d2c:	9b050513          	addi	a0,a0,-1616 # 800086d8 <syscalls+0x290>
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d38:	8756                	mv	a4,s5
    80004d3a:	012d86bb          	addw	a3,s11,s2
    80004d3e:	4581                	li	a1,0
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	cac080e7          	jalr	-852(ra) # 800039ee <readi>
    80004d4a:	2501                	sext.w	a0,a0
    80004d4c:	1aaa9963          	bne	s5,a0,80004efe <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d50:	6785                	lui	a5,0x1
    80004d52:	0127893b          	addw	s2,a5,s2
    80004d56:	77fd                	lui	a5,0xfffff
    80004d58:	01478a3b          	addw	s4,a5,s4
    80004d5c:	1f897163          	bgeu	s2,s8,80004f3e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d60:	02091593          	slli	a1,s2,0x20
    80004d64:	9181                	srli	a1,a1,0x20
    80004d66:	95ea                	add	a1,a1,s10
    80004d68:	855e                	mv	a0,s7
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	304080e7          	jalr	772(ra) # 8000106e <walkaddr>
    80004d72:	862a                	mv	a2,a0
    if(pa == 0)
    80004d74:	d955                	beqz	a0,80004d28 <exec+0xf0>
      n = PGSIZE;
    80004d76:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d78:	fd9a70e3          	bgeu	s4,s9,80004d38 <exec+0x100>
      n = sz - i;
    80004d7c:	8ad2                	mv	s5,s4
    80004d7e:	bf6d                	j	80004d38 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d80:	4901                	li	s2,0
  iunlockput(ip);
    80004d82:	8526                	mv	a0,s1
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	c18080e7          	jalr	-1000(ra) # 8000399c <iunlockput>
  end_op();
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	400080e7          	jalr	1024(ra) # 8000418c <end_op>
  p = myproc();
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	c1c080e7          	jalr	-996(ra) # 800019b0 <myproc>
    80004d9c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d9e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004da2:	6785                	lui	a5,0x1
    80004da4:	17fd                	addi	a5,a5,-1
    80004da6:	993e                	add	s2,s2,a5
    80004da8:	757d                	lui	a0,0xfffff
    80004daa:	00a977b3          	and	a5,s2,a0
    80004dae:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004db2:	6609                	lui	a2,0x2
    80004db4:	963e                	add	a2,a2,a5
    80004db6:	85be                	mv	a1,a5
    80004db8:	855e                	mv	a0,s7
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	668080e7          	jalr	1640(ra) # 80001422 <uvmalloc>
    80004dc2:	8b2a                	mv	s6,a0
  ip = 0;
    80004dc4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dc6:	12050c63          	beqz	a0,80004efe <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dca:	75f9                	lui	a1,0xffffe
    80004dcc:	95aa                	add	a1,a1,a0
    80004dce:	855e                	mv	a0,s7
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	870080e7          	jalr	-1936(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dd8:	7c7d                	lui	s8,0xfffff
    80004dda:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ddc:	e0043783          	ld	a5,-512(s0)
    80004de0:	6388                	ld	a0,0(a5)
    80004de2:	c535                	beqz	a0,80004e4e <exec+0x216>
    80004de4:	e9040993          	addi	s3,s0,-368
    80004de8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dec:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	076080e7          	jalr	118(ra) # 80000e64 <strlen>
    80004df6:	2505                	addiw	a0,a0,1
    80004df8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dfc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e00:	13896363          	bltu	s2,s8,80004f26 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e04:	e0043d83          	ld	s11,-512(s0)
    80004e08:	000dba03          	ld	s4,0(s11)
    80004e0c:	8552                	mv	a0,s4
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	056080e7          	jalr	86(ra) # 80000e64 <strlen>
    80004e16:	0015069b          	addiw	a3,a0,1
    80004e1a:	8652                	mv	a2,s4
    80004e1c:	85ca                	mv	a1,s2
    80004e1e:	855e                	mv	a0,s7
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	852080e7          	jalr	-1966(ra) # 80001672 <copyout>
    80004e28:	10054363          	bltz	a0,80004f2e <exec+0x2f6>
    ustack[argc] = sp;
    80004e2c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e30:	0485                	addi	s1,s1,1
    80004e32:	008d8793          	addi	a5,s11,8
    80004e36:	e0f43023          	sd	a5,-512(s0)
    80004e3a:	008db503          	ld	a0,8(s11)
    80004e3e:	c911                	beqz	a0,80004e52 <exec+0x21a>
    if(argc >= MAXARG)
    80004e40:	09a1                	addi	s3,s3,8
    80004e42:	fb3c96e3          	bne	s9,s3,80004dee <exec+0x1b6>
  sz = sz1;
    80004e46:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e4a:	4481                	li	s1,0
    80004e4c:	a84d                	j	80004efe <exec+0x2c6>
  sp = sz;
    80004e4e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e50:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e52:	00349793          	slli	a5,s1,0x3
    80004e56:	f9040713          	addi	a4,s0,-112
    80004e5a:	97ba                	add	a5,a5,a4
    80004e5c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e60:	00148693          	addi	a3,s1,1
    80004e64:	068e                	slli	a3,a3,0x3
    80004e66:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e6a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e6e:	01897663          	bgeu	s2,s8,80004e7a <exec+0x242>
  sz = sz1;
    80004e72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e76:	4481                	li	s1,0
    80004e78:	a059                	j	80004efe <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e7a:	e9040613          	addi	a2,s0,-368
    80004e7e:	85ca                	mv	a1,s2
    80004e80:	855e                	mv	a0,s7
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	7f0080e7          	jalr	2032(ra) # 80001672 <copyout>
    80004e8a:	0a054663          	bltz	a0,80004f36 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e8e:	058ab783          	ld	a5,88(s5)
    80004e92:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e96:	df843783          	ld	a5,-520(s0)
    80004e9a:	0007c703          	lbu	a4,0(a5)
    80004e9e:	cf11                	beqz	a4,80004eba <exec+0x282>
    80004ea0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ea2:	02f00693          	li	a3,47
    80004ea6:	a039                	j	80004eb4 <exec+0x27c>
      last = s+1;
    80004ea8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004eac:	0785                	addi	a5,a5,1
    80004eae:	fff7c703          	lbu	a4,-1(a5)
    80004eb2:	c701                	beqz	a4,80004eba <exec+0x282>
    if(*s == '/')
    80004eb4:	fed71ce3          	bne	a4,a3,80004eac <exec+0x274>
    80004eb8:	bfc5                	j	80004ea8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eba:	4641                	li	a2,16
    80004ebc:	df843583          	ld	a1,-520(s0)
    80004ec0:	158a8513          	addi	a0,s5,344
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	f6e080e7          	jalr	-146(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ecc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ed0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ed4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ed8:	058ab783          	ld	a5,88(s5)
    80004edc:	e6843703          	ld	a4,-408(s0)
    80004ee0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ee2:	058ab783          	ld	a5,88(s5)
    80004ee6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eea:	85ea                	mv	a1,s10
    80004eec:	ffffd097          	auipc	ra,0xffffd
    80004ef0:	c24080e7          	jalr	-988(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ef4:	0004851b          	sext.w	a0,s1
    80004ef8:	bbe1                	j	80004cd0 <exec+0x98>
    80004efa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004efe:	e0843583          	ld	a1,-504(s0)
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	c0c080e7          	jalr	-1012(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f0c:	da0498e3          	bnez	s1,80004cbc <exec+0x84>
  return -1;
    80004f10:	557d                	li	a0,-1
    80004f12:	bb7d                	j	80004cd0 <exec+0x98>
    80004f14:	e1243423          	sd	s2,-504(s0)
    80004f18:	b7dd                	j	80004efe <exec+0x2c6>
    80004f1a:	e1243423          	sd	s2,-504(s0)
    80004f1e:	b7c5                	j	80004efe <exec+0x2c6>
    80004f20:	e1243423          	sd	s2,-504(s0)
    80004f24:	bfe9                	j	80004efe <exec+0x2c6>
  sz = sz1;
    80004f26:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f2a:	4481                	li	s1,0
    80004f2c:	bfc9                	j	80004efe <exec+0x2c6>
  sz = sz1;
    80004f2e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f32:	4481                	li	s1,0
    80004f34:	b7e9                	j	80004efe <exec+0x2c6>
  sz = sz1;
    80004f36:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3a:	4481                	li	s1,0
    80004f3c:	b7c9                	j	80004efe <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f3e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f42:	2b05                	addiw	s6,s6,1
    80004f44:	0389899b          	addiw	s3,s3,56
    80004f48:	e8845783          	lhu	a5,-376(s0)
    80004f4c:	e2fb5be3          	bge	s6,a5,80004d82 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f50:	2981                	sext.w	s3,s3
    80004f52:	03800713          	li	a4,56
    80004f56:	86ce                	mv	a3,s3
    80004f58:	e1840613          	addi	a2,s0,-488
    80004f5c:	4581                	li	a1,0
    80004f5e:	8526                	mv	a0,s1
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	a8e080e7          	jalr	-1394(ra) # 800039ee <readi>
    80004f68:	03800793          	li	a5,56
    80004f6c:	f8f517e3          	bne	a0,a5,80004efa <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f70:	e1842783          	lw	a5,-488(s0)
    80004f74:	4705                	li	a4,1
    80004f76:	fce796e3          	bne	a5,a4,80004f42 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f7a:	e4043603          	ld	a2,-448(s0)
    80004f7e:	e3843783          	ld	a5,-456(s0)
    80004f82:	f8f669e3          	bltu	a2,a5,80004f14 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f86:	e2843783          	ld	a5,-472(s0)
    80004f8a:	963e                	add	a2,a2,a5
    80004f8c:	f8f667e3          	bltu	a2,a5,80004f1a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f90:	85ca                	mv	a1,s2
    80004f92:	855e                	mv	a0,s7
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	48e080e7          	jalr	1166(ra) # 80001422 <uvmalloc>
    80004f9c:	e0a43423          	sd	a0,-504(s0)
    80004fa0:	d141                	beqz	a0,80004f20 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004fa2:	e2843d03          	ld	s10,-472(s0)
    80004fa6:	df043783          	ld	a5,-528(s0)
    80004faa:	00fd77b3          	and	a5,s10,a5
    80004fae:	fba1                	bnez	a5,80004efe <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fb0:	e2042d83          	lw	s11,-480(s0)
    80004fb4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fb8:	f80c03e3          	beqz	s8,80004f3e <exec+0x306>
    80004fbc:	8a62                	mv	s4,s8
    80004fbe:	4901                	li	s2,0
    80004fc0:	b345                	j	80004d60 <exec+0x128>

0000000080004fc2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fc2:	7179                	addi	sp,sp,-48
    80004fc4:	f406                	sd	ra,40(sp)
    80004fc6:	f022                	sd	s0,32(sp)
    80004fc8:	ec26                	sd	s1,24(sp)
    80004fca:	e84a                	sd	s2,16(sp)
    80004fcc:	1800                	addi	s0,sp,48
    80004fce:	892e                	mv	s2,a1
    80004fd0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fd2:	fdc40593          	addi	a1,s0,-36
    80004fd6:	ffffe097          	auipc	ra,0xffffe
    80004fda:	ba4080e7          	jalr	-1116(ra) # 80002b7a <argint>
    80004fde:	04054063          	bltz	a0,8000501e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fe2:	fdc42703          	lw	a4,-36(s0)
    80004fe6:	47bd                	li	a5,15
    80004fe8:	02e7ed63          	bltu	a5,a4,80005022 <argfd+0x60>
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	9c4080e7          	jalr	-1596(ra) # 800019b0 <myproc>
    80004ff4:	fdc42703          	lw	a4,-36(s0)
    80004ff8:	01a70793          	addi	a5,a4,26
    80004ffc:	078e                	slli	a5,a5,0x3
    80004ffe:	953e                	add	a0,a0,a5
    80005000:	611c                	ld	a5,0(a0)
    80005002:	c395                	beqz	a5,80005026 <argfd+0x64>
    return -1;
  if(pfd)
    80005004:	00090463          	beqz	s2,8000500c <argfd+0x4a>
    *pfd = fd;
    80005008:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000500c:	4501                	li	a0,0
  if(pf)
    8000500e:	c091                	beqz	s1,80005012 <argfd+0x50>
    *pf = f;
    80005010:	e09c                	sd	a5,0(s1)
}
    80005012:	70a2                	ld	ra,40(sp)
    80005014:	7402                	ld	s0,32(sp)
    80005016:	64e2                	ld	s1,24(sp)
    80005018:	6942                	ld	s2,16(sp)
    8000501a:	6145                	addi	sp,sp,48
    8000501c:	8082                	ret
    return -1;
    8000501e:	557d                	li	a0,-1
    80005020:	bfcd                	j	80005012 <argfd+0x50>
    return -1;
    80005022:	557d                	li	a0,-1
    80005024:	b7fd                	j	80005012 <argfd+0x50>
    80005026:	557d                	li	a0,-1
    80005028:	b7ed                	j	80005012 <argfd+0x50>

000000008000502a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000502a:	1101                	addi	sp,sp,-32
    8000502c:	ec06                	sd	ra,24(sp)
    8000502e:	e822                	sd	s0,16(sp)
    80005030:	e426                	sd	s1,8(sp)
    80005032:	1000                	addi	s0,sp,32
    80005034:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	97a080e7          	jalr	-1670(ra) # 800019b0 <myproc>
    8000503e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005040:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005044:	4501                	li	a0,0
    80005046:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005048:	6398                	ld	a4,0(a5)
    8000504a:	cb19                	beqz	a4,80005060 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000504c:	2505                	addiw	a0,a0,1
    8000504e:	07a1                	addi	a5,a5,8
    80005050:	fed51ce3          	bne	a0,a3,80005048 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005054:	557d                	li	a0,-1
}
    80005056:	60e2                	ld	ra,24(sp)
    80005058:	6442                	ld	s0,16(sp)
    8000505a:	64a2                	ld	s1,8(sp)
    8000505c:	6105                	addi	sp,sp,32
    8000505e:	8082                	ret
      p->ofile[fd] = f;
    80005060:	01a50793          	addi	a5,a0,26
    80005064:	078e                	slli	a5,a5,0x3
    80005066:	963e                	add	a2,a2,a5
    80005068:	e204                	sd	s1,0(a2)
      return fd;
    8000506a:	b7f5                	j	80005056 <fdalloc+0x2c>

000000008000506c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000506c:	715d                	addi	sp,sp,-80
    8000506e:	e486                	sd	ra,72(sp)
    80005070:	e0a2                	sd	s0,64(sp)
    80005072:	fc26                	sd	s1,56(sp)
    80005074:	f84a                	sd	s2,48(sp)
    80005076:	f44e                	sd	s3,40(sp)
    80005078:	f052                	sd	s4,32(sp)
    8000507a:	ec56                	sd	s5,24(sp)
    8000507c:	0880                	addi	s0,sp,80
    8000507e:	89ae                	mv	s3,a1
    80005080:	8ab2                	mv	s5,a2
    80005082:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005084:	fb040593          	addi	a1,s0,-80
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	e86080e7          	jalr	-378(ra) # 80003f0e <nameiparent>
    80005090:	892a                	mv	s2,a0
    80005092:	12050f63          	beqz	a0,800051d0 <create+0x164>
    return 0;

  ilock(dp);
    80005096:	ffffe097          	auipc	ra,0xffffe
    8000509a:	6a4080e7          	jalr	1700(ra) # 8000373a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000509e:	4601                	li	a2,0
    800050a0:	fb040593          	addi	a1,s0,-80
    800050a4:	854a                	mv	a0,s2
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	b78080e7          	jalr	-1160(ra) # 80003c1e <dirlookup>
    800050ae:	84aa                	mv	s1,a0
    800050b0:	c921                	beqz	a0,80005100 <create+0x94>
    iunlockput(dp);
    800050b2:	854a                	mv	a0,s2
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	8e8080e7          	jalr	-1816(ra) # 8000399c <iunlockput>
    ilock(ip);
    800050bc:	8526                	mv	a0,s1
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	67c080e7          	jalr	1660(ra) # 8000373a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050c6:	2981                	sext.w	s3,s3
    800050c8:	4789                	li	a5,2
    800050ca:	02f99463          	bne	s3,a5,800050f2 <create+0x86>
    800050ce:	0444d783          	lhu	a5,68(s1)
    800050d2:	37f9                	addiw	a5,a5,-2
    800050d4:	17c2                	slli	a5,a5,0x30
    800050d6:	93c1                	srli	a5,a5,0x30
    800050d8:	4705                	li	a4,1
    800050da:	00f76c63          	bltu	a4,a5,800050f2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050de:	8526                	mv	a0,s1
    800050e0:	60a6                	ld	ra,72(sp)
    800050e2:	6406                	ld	s0,64(sp)
    800050e4:	74e2                	ld	s1,56(sp)
    800050e6:	7942                	ld	s2,48(sp)
    800050e8:	79a2                	ld	s3,40(sp)
    800050ea:	7a02                	ld	s4,32(sp)
    800050ec:	6ae2                	ld	s5,24(sp)
    800050ee:	6161                	addi	sp,sp,80
    800050f0:	8082                	ret
    iunlockput(ip);
    800050f2:	8526                	mv	a0,s1
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	8a8080e7          	jalr	-1880(ra) # 8000399c <iunlockput>
    return 0;
    800050fc:	4481                	li	s1,0
    800050fe:	b7c5                	j	800050de <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005100:	85ce                	mv	a1,s3
    80005102:	00092503          	lw	a0,0(s2)
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	49c080e7          	jalr	1180(ra) # 800035a2 <ialloc>
    8000510e:	84aa                	mv	s1,a0
    80005110:	c529                	beqz	a0,8000515a <create+0xee>
  ilock(ip);
    80005112:	ffffe097          	auipc	ra,0xffffe
    80005116:	628080e7          	jalr	1576(ra) # 8000373a <ilock>
  ip->major = major;
    8000511a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000511e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005122:	4785                	li	a5,1
    80005124:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	546080e7          	jalr	1350(ra) # 80003670 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005132:	2981                	sext.w	s3,s3
    80005134:	4785                	li	a5,1
    80005136:	02f98a63          	beq	s3,a5,8000516a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000513a:	40d0                	lw	a2,4(s1)
    8000513c:	fb040593          	addi	a1,s0,-80
    80005140:	854a                	mv	a0,s2
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	cec080e7          	jalr	-788(ra) # 80003e2e <dirlink>
    8000514a:	06054b63          	bltz	a0,800051c0 <create+0x154>
  iunlockput(dp);
    8000514e:	854a                	mv	a0,s2
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	84c080e7          	jalr	-1972(ra) # 8000399c <iunlockput>
  return ip;
    80005158:	b759                	j	800050de <create+0x72>
    panic("create: ialloc");
    8000515a:	00003517          	auipc	a0,0x3
    8000515e:	59e50513          	addi	a0,a0,1438 # 800086f8 <syscalls+0x2b0>
    80005162:	ffffb097          	auipc	ra,0xffffb
    80005166:	3dc080e7          	jalr	988(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000516a:	04a95783          	lhu	a5,74(s2)
    8000516e:	2785                	addiw	a5,a5,1
    80005170:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005174:	854a                	mv	a0,s2
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	4fa080e7          	jalr	1274(ra) # 80003670 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000517e:	40d0                	lw	a2,4(s1)
    80005180:	00003597          	auipc	a1,0x3
    80005184:	58858593          	addi	a1,a1,1416 # 80008708 <syscalls+0x2c0>
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	ca4080e7          	jalr	-860(ra) # 80003e2e <dirlink>
    80005192:	00054f63          	bltz	a0,800051b0 <create+0x144>
    80005196:	00492603          	lw	a2,4(s2)
    8000519a:	00003597          	auipc	a1,0x3
    8000519e:	57658593          	addi	a1,a1,1398 # 80008710 <syscalls+0x2c8>
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	c8a080e7          	jalr	-886(ra) # 80003e2e <dirlink>
    800051ac:	f80557e3          	bgez	a0,8000513a <create+0xce>
      panic("create dots");
    800051b0:	00003517          	auipc	a0,0x3
    800051b4:	56850513          	addi	a0,a0,1384 # 80008718 <syscalls+0x2d0>
    800051b8:	ffffb097          	auipc	ra,0xffffb
    800051bc:	386080e7          	jalr	902(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051c0:	00003517          	auipc	a0,0x3
    800051c4:	56850513          	addi	a0,a0,1384 # 80008728 <syscalls+0x2e0>
    800051c8:	ffffb097          	auipc	ra,0xffffb
    800051cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
    return 0;
    800051d0:	84aa                	mv	s1,a0
    800051d2:	b731                	j	800050de <create+0x72>

00000000800051d4 <sys_dup>:
{
    800051d4:	7179                	addi	sp,sp,-48
    800051d6:	f406                	sd	ra,40(sp)
    800051d8:	f022                	sd	s0,32(sp)
    800051da:	ec26                	sd	s1,24(sp)
    800051dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051de:	fd840613          	addi	a2,s0,-40
    800051e2:	4581                	li	a1,0
    800051e4:	4501                	li	a0,0
    800051e6:	00000097          	auipc	ra,0x0
    800051ea:	ddc080e7          	jalr	-548(ra) # 80004fc2 <argfd>
    return -1;
    800051ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051f0:	02054363          	bltz	a0,80005216 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051f4:	fd843503          	ld	a0,-40(s0)
    800051f8:	00000097          	auipc	ra,0x0
    800051fc:	e32080e7          	jalr	-462(ra) # 8000502a <fdalloc>
    80005200:	84aa                	mv	s1,a0
    return -1;
    80005202:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005204:	00054963          	bltz	a0,80005216 <sys_dup+0x42>
  filedup(f);
    80005208:	fd843503          	ld	a0,-40(s0)
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	37a080e7          	jalr	890(ra) # 80004586 <filedup>
  return fd;
    80005214:	87a6                	mv	a5,s1
}
    80005216:	853e                	mv	a0,a5
    80005218:	70a2                	ld	ra,40(sp)
    8000521a:	7402                	ld	s0,32(sp)
    8000521c:	64e2                	ld	s1,24(sp)
    8000521e:	6145                	addi	sp,sp,48
    80005220:	8082                	ret

0000000080005222 <sys_read>:
{
    80005222:	7179                	addi	sp,sp,-48
    80005224:	f406                	sd	ra,40(sp)
    80005226:	f022                	sd	s0,32(sp)
    80005228:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522a:	fe840613          	addi	a2,s0,-24
    8000522e:	4581                	li	a1,0
    80005230:	4501                	li	a0,0
    80005232:	00000097          	auipc	ra,0x0
    80005236:	d90080e7          	jalr	-624(ra) # 80004fc2 <argfd>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523c:	04054163          	bltz	a0,8000527e <sys_read+0x5c>
    80005240:	fe440593          	addi	a1,s0,-28
    80005244:	4509                	li	a0,2
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	934080e7          	jalr	-1740(ra) # 80002b7a <argint>
    return -1;
    8000524e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005250:	02054763          	bltz	a0,8000527e <sys_read+0x5c>
    80005254:	fd840593          	addi	a1,s0,-40
    80005258:	4505                	li	a0,1
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	942080e7          	jalr	-1726(ra) # 80002b9c <argaddr>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005264:	00054d63          	bltz	a0,8000527e <sys_read+0x5c>
  return fileread(f, p, n);
    80005268:	fe442603          	lw	a2,-28(s0)
    8000526c:	fd843583          	ld	a1,-40(s0)
    80005270:	fe843503          	ld	a0,-24(s0)
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	49e080e7          	jalr	1182(ra) # 80004712 <fileread>
    8000527c:	87aa                	mv	a5,a0
}
    8000527e:	853e                	mv	a0,a5
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret

0000000080005288 <sys_write>:
{
    80005288:	7179                	addi	sp,sp,-48
    8000528a:	f406                	sd	ra,40(sp)
    8000528c:	f022                	sd	s0,32(sp)
    8000528e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005290:	fe840613          	addi	a2,s0,-24
    80005294:	4581                	li	a1,0
    80005296:	4501                	li	a0,0
    80005298:	00000097          	auipc	ra,0x0
    8000529c:	d2a080e7          	jalr	-726(ra) # 80004fc2 <argfd>
    return -1;
    800052a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	04054163          	bltz	a0,800052e4 <sys_write+0x5c>
    800052a6:	fe440593          	addi	a1,s0,-28
    800052aa:	4509                	li	a0,2
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	8ce080e7          	jalr	-1842(ra) # 80002b7a <argint>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b6:	02054763          	bltz	a0,800052e4 <sys_write+0x5c>
    800052ba:	fd840593          	addi	a1,s0,-40
    800052be:	4505                	li	a0,1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	8dc080e7          	jalr	-1828(ra) # 80002b9c <argaddr>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	00054d63          	bltz	a0,800052e4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052ce:	fe442603          	lw	a2,-28(s0)
    800052d2:	fd843583          	ld	a1,-40(s0)
    800052d6:	fe843503          	ld	a0,-24(s0)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	4fa080e7          	jalr	1274(ra) # 800047d4 <filewrite>
    800052e2:	87aa                	mv	a5,a0
}
    800052e4:	853e                	mv	a0,a5
    800052e6:	70a2                	ld	ra,40(sp)
    800052e8:	7402                	ld	s0,32(sp)
    800052ea:	6145                	addi	sp,sp,48
    800052ec:	8082                	ret

00000000800052ee <sys_close>:
{
    800052ee:	1101                	addi	sp,sp,-32
    800052f0:	ec06                	sd	ra,24(sp)
    800052f2:	e822                	sd	s0,16(sp)
    800052f4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052f6:	fe040613          	addi	a2,s0,-32
    800052fa:	fec40593          	addi	a1,s0,-20
    800052fe:	4501                	li	a0,0
    80005300:	00000097          	auipc	ra,0x0
    80005304:	cc2080e7          	jalr	-830(ra) # 80004fc2 <argfd>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000530a:	02054463          	bltz	a0,80005332 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	6a2080e7          	jalr	1698(ra) # 800019b0 <myproc>
    80005316:	fec42783          	lw	a5,-20(s0)
    8000531a:	07e9                	addi	a5,a5,26
    8000531c:	078e                	slli	a5,a5,0x3
    8000531e:	97aa                	add	a5,a5,a0
    80005320:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005324:	fe043503          	ld	a0,-32(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	2b0080e7          	jalr	688(ra) # 800045d8 <fileclose>
  return 0;
    80005330:	4781                	li	a5,0
}
    80005332:	853e                	mv	a0,a5
    80005334:	60e2                	ld	ra,24(sp)
    80005336:	6442                	ld	s0,16(sp)
    80005338:	6105                	addi	sp,sp,32
    8000533a:	8082                	ret

000000008000533c <sys_fstat>:
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	c76080e7          	jalr	-906(ra) # 80004fc2 <argfd>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005356:	02054563          	bltz	a0,80005380 <sys_fstat+0x44>
    8000535a:	fe040593          	addi	a1,s0,-32
    8000535e:	4505                	li	a0,1
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	83c080e7          	jalr	-1988(ra) # 80002b9c <argaddr>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000536a:	00054b63          	bltz	a0,80005380 <sys_fstat+0x44>
  return filestat(f, st);
    8000536e:	fe043583          	ld	a1,-32(s0)
    80005372:	fe843503          	ld	a0,-24(s0)
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	32a080e7          	jalr	810(ra) # 800046a0 <filestat>
    8000537e:	87aa                	mv	a5,a0
}
    80005380:	853e                	mv	a0,a5
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	6105                	addi	sp,sp,32
    80005388:	8082                	ret

000000008000538a <sys_link>:
{
    8000538a:	7169                	addi	sp,sp,-304
    8000538c:	f606                	sd	ra,296(sp)
    8000538e:	f222                	sd	s0,288(sp)
    80005390:	ee26                	sd	s1,280(sp)
    80005392:	ea4a                	sd	s2,272(sp)
    80005394:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005396:	08000613          	li	a2,128
    8000539a:	ed040593          	addi	a1,s0,-304
    8000539e:	4501                	li	a0,0
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	81e080e7          	jalr	-2018(ra) # 80002bbe <argstr>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053aa:	10054e63          	bltz	a0,800054c6 <sys_link+0x13c>
    800053ae:	08000613          	li	a2,128
    800053b2:	f5040593          	addi	a1,s0,-176
    800053b6:	4505                	li	a0,1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	806080e7          	jalr	-2042(ra) # 80002bbe <argstr>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c2:	10054263          	bltz	a0,800054c6 <sys_link+0x13c>
  begin_op();
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	d46080e7          	jalr	-698(ra) # 8000410c <begin_op>
  if((ip = namei(old)) == 0){
    800053ce:	ed040513          	addi	a0,s0,-304
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	b1e080e7          	jalr	-1250(ra) # 80003ef0 <namei>
    800053da:	84aa                	mv	s1,a0
    800053dc:	c551                	beqz	a0,80005468 <sys_link+0xde>
  ilock(ip);
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	35c080e7          	jalr	860(ra) # 8000373a <ilock>
  if(ip->type == T_DIR){
    800053e6:	04449703          	lh	a4,68(s1)
    800053ea:	4785                	li	a5,1
    800053ec:	08f70463          	beq	a4,a5,80005474 <sys_link+0xea>
  ip->nlink++;
    800053f0:	04a4d783          	lhu	a5,74(s1)
    800053f4:	2785                	addiw	a5,a5,1
    800053f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053fa:	8526                	mv	a0,s1
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	274080e7          	jalr	628(ra) # 80003670 <iupdate>
  iunlock(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	3f6080e7          	jalr	1014(ra) # 800037fc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000540e:	fd040593          	addi	a1,s0,-48
    80005412:	f5040513          	addi	a0,s0,-176
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	af8080e7          	jalr	-1288(ra) # 80003f0e <nameiparent>
    8000541e:	892a                	mv	s2,a0
    80005420:	c935                	beqz	a0,80005494 <sys_link+0x10a>
  ilock(dp);
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	318080e7          	jalr	792(ra) # 8000373a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000542a:	00092703          	lw	a4,0(s2)
    8000542e:	409c                	lw	a5,0(s1)
    80005430:	04f71d63          	bne	a4,a5,8000548a <sys_link+0x100>
    80005434:	40d0                	lw	a2,4(s1)
    80005436:	fd040593          	addi	a1,s0,-48
    8000543a:	854a                	mv	a0,s2
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	9f2080e7          	jalr	-1550(ra) # 80003e2e <dirlink>
    80005444:	04054363          	bltz	a0,8000548a <sys_link+0x100>
  iunlockput(dp);
    80005448:	854a                	mv	a0,s2
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	552080e7          	jalr	1362(ra) # 8000399c <iunlockput>
  iput(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	4a0080e7          	jalr	1184(ra) # 800038f4 <iput>
  end_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	d30080e7          	jalr	-720(ra) # 8000418c <end_op>
  return 0;
    80005464:	4781                	li	a5,0
    80005466:	a085                	j	800054c6 <sys_link+0x13c>
    end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	d24080e7          	jalr	-732(ra) # 8000418c <end_op>
    return -1;
    80005470:	57fd                	li	a5,-1
    80005472:	a891                	j	800054c6 <sys_link+0x13c>
    iunlockput(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	526080e7          	jalr	1318(ra) # 8000399c <iunlockput>
    end_op();
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	d0e080e7          	jalr	-754(ra) # 8000418c <end_op>
    return -1;
    80005486:	57fd                	li	a5,-1
    80005488:	a83d                	j	800054c6 <sys_link+0x13c>
    iunlockput(dp);
    8000548a:	854a                	mv	a0,s2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	510080e7          	jalr	1296(ra) # 8000399c <iunlockput>
  ilock(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	2a4080e7          	jalr	676(ra) # 8000373a <ilock>
  ip->nlink--;
    8000549e:	04a4d783          	lhu	a5,74(s1)
    800054a2:	37fd                	addiw	a5,a5,-1
    800054a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	1c6080e7          	jalr	454(ra) # 80003670 <iupdate>
  iunlockput(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	4e8080e7          	jalr	1256(ra) # 8000399c <iunlockput>
  end_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	cd0080e7          	jalr	-816(ra) # 8000418c <end_op>
  return -1;
    800054c4:	57fd                	li	a5,-1
}
    800054c6:	853e                	mv	a0,a5
    800054c8:	70b2                	ld	ra,296(sp)
    800054ca:	7412                	ld	s0,288(sp)
    800054cc:	64f2                	ld	s1,280(sp)
    800054ce:	6952                	ld	s2,272(sp)
    800054d0:	6155                	addi	sp,sp,304
    800054d2:	8082                	ret

00000000800054d4 <sys_unlink>:
{
    800054d4:	7151                	addi	sp,sp,-240
    800054d6:	f586                	sd	ra,232(sp)
    800054d8:	f1a2                	sd	s0,224(sp)
    800054da:	eda6                	sd	s1,216(sp)
    800054dc:	e9ca                	sd	s2,208(sp)
    800054de:	e5ce                	sd	s3,200(sp)
    800054e0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054e2:	08000613          	li	a2,128
    800054e6:	f3040593          	addi	a1,s0,-208
    800054ea:	4501                	li	a0,0
    800054ec:	ffffd097          	auipc	ra,0xffffd
    800054f0:	6d2080e7          	jalr	1746(ra) # 80002bbe <argstr>
    800054f4:	18054163          	bltz	a0,80005676 <sys_unlink+0x1a2>
  begin_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	c14080e7          	jalr	-1004(ra) # 8000410c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005500:	fb040593          	addi	a1,s0,-80
    80005504:	f3040513          	addi	a0,s0,-208
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	a06080e7          	jalr	-1530(ra) # 80003f0e <nameiparent>
    80005510:	84aa                	mv	s1,a0
    80005512:	c979                	beqz	a0,800055e8 <sys_unlink+0x114>
  ilock(dp);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	226080e7          	jalr	550(ra) # 8000373a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000551c:	00003597          	auipc	a1,0x3
    80005520:	1ec58593          	addi	a1,a1,492 # 80008708 <syscalls+0x2c0>
    80005524:	fb040513          	addi	a0,s0,-80
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	6dc080e7          	jalr	1756(ra) # 80003c04 <namecmp>
    80005530:	14050a63          	beqz	a0,80005684 <sys_unlink+0x1b0>
    80005534:	00003597          	auipc	a1,0x3
    80005538:	1dc58593          	addi	a1,a1,476 # 80008710 <syscalls+0x2c8>
    8000553c:	fb040513          	addi	a0,s0,-80
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	6c4080e7          	jalr	1732(ra) # 80003c04 <namecmp>
    80005548:	12050e63          	beqz	a0,80005684 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000554c:	f2c40613          	addi	a2,s0,-212
    80005550:	fb040593          	addi	a1,s0,-80
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	6c8080e7          	jalr	1736(ra) # 80003c1e <dirlookup>
    8000555e:	892a                	mv	s2,a0
    80005560:	12050263          	beqz	a0,80005684 <sys_unlink+0x1b0>
  ilock(ip);
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	1d6080e7          	jalr	470(ra) # 8000373a <ilock>
  if(ip->nlink < 1)
    8000556c:	04a91783          	lh	a5,74(s2)
    80005570:	08f05263          	blez	a5,800055f4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005574:	04491703          	lh	a4,68(s2)
    80005578:	4785                	li	a5,1
    8000557a:	08f70563          	beq	a4,a5,80005604 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000557e:	4641                	li	a2,16
    80005580:	4581                	li	a1,0
    80005582:	fc040513          	addi	a0,s0,-64
    80005586:	ffffb097          	auipc	ra,0xffffb
    8000558a:	75a080e7          	jalr	1882(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000558e:	4741                	li	a4,16
    80005590:	f2c42683          	lw	a3,-212(s0)
    80005594:	fc040613          	addi	a2,s0,-64
    80005598:	4581                	li	a1,0
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	54a080e7          	jalr	1354(ra) # 80003ae6 <writei>
    800055a4:	47c1                	li	a5,16
    800055a6:	0af51563          	bne	a0,a5,80005650 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055aa:	04491703          	lh	a4,68(s2)
    800055ae:	4785                	li	a5,1
    800055b0:	0af70863          	beq	a4,a5,80005660 <sys_unlink+0x18c>
  iunlockput(dp);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	3e6080e7          	jalr	998(ra) # 8000399c <iunlockput>
  ip->nlink--;
    800055be:	04a95783          	lhu	a5,74(s2)
    800055c2:	37fd                	addiw	a5,a5,-1
    800055c4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055c8:	854a                	mv	a0,s2
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	0a6080e7          	jalr	166(ra) # 80003670 <iupdate>
  iunlockput(ip);
    800055d2:	854a                	mv	a0,s2
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	3c8080e7          	jalr	968(ra) # 8000399c <iunlockput>
  end_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	bb0080e7          	jalr	-1104(ra) # 8000418c <end_op>
  return 0;
    800055e4:	4501                	li	a0,0
    800055e6:	a84d                	j	80005698 <sys_unlink+0x1c4>
    end_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	ba4080e7          	jalr	-1116(ra) # 8000418c <end_op>
    return -1;
    800055f0:	557d                	li	a0,-1
    800055f2:	a05d                	j	80005698 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055f4:	00003517          	auipc	a0,0x3
    800055f8:	14450513          	addi	a0,a0,324 # 80008738 <syscalls+0x2f0>
    800055fc:	ffffb097          	auipc	ra,0xffffb
    80005600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005604:	04c92703          	lw	a4,76(s2)
    80005608:	02000793          	li	a5,32
    8000560c:	f6e7f9e3          	bgeu	a5,a4,8000557e <sys_unlink+0xaa>
    80005610:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005614:	4741                	li	a4,16
    80005616:	86ce                	mv	a3,s3
    80005618:	f1840613          	addi	a2,s0,-232
    8000561c:	4581                	li	a1,0
    8000561e:	854a                	mv	a0,s2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	3ce080e7          	jalr	974(ra) # 800039ee <readi>
    80005628:	47c1                	li	a5,16
    8000562a:	00f51b63          	bne	a0,a5,80005640 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000562e:	f1845783          	lhu	a5,-232(s0)
    80005632:	e7a1                	bnez	a5,8000567a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005634:	29c1                	addiw	s3,s3,16
    80005636:	04c92783          	lw	a5,76(s2)
    8000563a:	fcf9ede3          	bltu	s3,a5,80005614 <sys_unlink+0x140>
    8000563e:	b781                	j	8000557e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005640:	00003517          	auipc	a0,0x3
    80005644:	11050513          	addi	a0,a0,272 # 80008750 <syscalls+0x308>
    80005648:	ffffb097          	auipc	ra,0xffffb
    8000564c:	ef6080e7          	jalr	-266(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005650:	00003517          	auipc	a0,0x3
    80005654:	11850513          	addi	a0,a0,280 # 80008768 <syscalls+0x320>
    80005658:	ffffb097          	auipc	ra,0xffffb
    8000565c:	ee6080e7          	jalr	-282(ra) # 8000053e <panic>
    dp->nlink--;
    80005660:	04a4d783          	lhu	a5,74(s1)
    80005664:	37fd                	addiw	a5,a5,-1
    80005666:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	004080e7          	jalr	4(ra) # 80003670 <iupdate>
    80005674:	b781                	j	800055b4 <sys_unlink+0xe0>
    return -1;
    80005676:	557d                	li	a0,-1
    80005678:	a005                	j	80005698 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	320080e7          	jalr	800(ra) # 8000399c <iunlockput>
  iunlockput(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	316080e7          	jalr	790(ra) # 8000399c <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	afe080e7          	jalr	-1282(ra) # 8000418c <end_op>
  return -1;
    80005696:	557d                	li	a0,-1
}
    80005698:	70ae                	ld	ra,232(sp)
    8000569a:	740e                	ld	s0,224(sp)
    8000569c:	64ee                	ld	s1,216(sp)
    8000569e:	694e                	ld	s2,208(sp)
    800056a0:	69ae                	ld	s3,200(sp)
    800056a2:	616d                	addi	sp,sp,240
    800056a4:	8082                	ret

00000000800056a6 <sys_open>:

uint64
sys_open(void)
{
    800056a6:	7131                	addi	sp,sp,-192
    800056a8:	fd06                	sd	ra,184(sp)
    800056aa:	f922                	sd	s0,176(sp)
    800056ac:	f526                	sd	s1,168(sp)
    800056ae:	f14a                	sd	s2,160(sp)
    800056b0:	ed4e                	sd	s3,152(sp)
    800056b2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056b4:	08000613          	li	a2,128
    800056b8:	f5040593          	addi	a1,s0,-176
    800056bc:	4501                	li	a0,0
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	500080e7          	jalr	1280(ra) # 80002bbe <argstr>
    return -1;
    800056c6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c8:	0c054163          	bltz	a0,8000578a <sys_open+0xe4>
    800056cc:	f4c40593          	addi	a1,s0,-180
    800056d0:	4505                	li	a0,1
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	4a8080e7          	jalr	1192(ra) # 80002b7a <argint>
    800056da:	0a054863          	bltz	a0,8000578a <sys_open+0xe4>

  begin_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	a2e080e7          	jalr	-1490(ra) # 8000410c <begin_op>

  if(omode & O_CREATE){
    800056e6:	f4c42783          	lw	a5,-180(s0)
    800056ea:	2007f793          	andi	a5,a5,512
    800056ee:	cbdd                	beqz	a5,800057a4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056f0:	4681                	li	a3,0
    800056f2:	4601                	li	a2,0
    800056f4:	4589                	li	a1,2
    800056f6:	f5040513          	addi	a0,s0,-176
    800056fa:	00000097          	auipc	ra,0x0
    800056fe:	972080e7          	jalr	-1678(ra) # 8000506c <create>
    80005702:	892a                	mv	s2,a0
    if(ip == 0){
    80005704:	c959                	beqz	a0,8000579a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005706:	04491703          	lh	a4,68(s2)
    8000570a:	478d                	li	a5,3
    8000570c:	00f71763          	bne	a4,a5,8000571a <sys_open+0x74>
    80005710:	04695703          	lhu	a4,70(s2)
    80005714:	47a5                	li	a5,9
    80005716:	0ce7ec63          	bltu	a5,a4,800057ee <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	e02080e7          	jalr	-510(ra) # 8000451c <filealloc>
    80005722:	89aa                	mv	s3,a0
    80005724:	10050263          	beqz	a0,80005828 <sys_open+0x182>
    80005728:	00000097          	auipc	ra,0x0
    8000572c:	902080e7          	jalr	-1790(ra) # 8000502a <fdalloc>
    80005730:	84aa                	mv	s1,a0
    80005732:	0e054663          	bltz	a0,8000581e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005736:	04491703          	lh	a4,68(s2)
    8000573a:	478d                	li	a5,3
    8000573c:	0cf70463          	beq	a4,a5,80005804 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005740:	4789                	li	a5,2
    80005742:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005746:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000574a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000574e:	f4c42783          	lw	a5,-180(s0)
    80005752:	0017c713          	xori	a4,a5,1
    80005756:	8b05                	andi	a4,a4,1
    80005758:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000575c:	0037f713          	andi	a4,a5,3
    80005760:	00e03733          	snez	a4,a4
    80005764:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005768:	4007f793          	andi	a5,a5,1024
    8000576c:	c791                	beqz	a5,80005778 <sys_open+0xd2>
    8000576e:	04491703          	lh	a4,68(s2)
    80005772:	4789                	li	a5,2
    80005774:	08f70f63          	beq	a4,a5,80005812 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	082080e7          	jalr	130(ra) # 800037fc <iunlock>
  end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	a0a080e7          	jalr	-1526(ra) # 8000418c <end_op>

  return fd;
}
    8000578a:	8526                	mv	a0,s1
    8000578c:	70ea                	ld	ra,184(sp)
    8000578e:	744a                	ld	s0,176(sp)
    80005790:	74aa                	ld	s1,168(sp)
    80005792:	790a                	ld	s2,160(sp)
    80005794:	69ea                	ld	s3,152(sp)
    80005796:	6129                	addi	sp,sp,192
    80005798:	8082                	ret
      end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	9f2080e7          	jalr	-1550(ra) # 8000418c <end_op>
      return -1;
    800057a2:	b7e5                	j	8000578a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057a4:	f5040513          	addi	a0,s0,-176
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	748080e7          	jalr	1864(ra) # 80003ef0 <namei>
    800057b0:	892a                	mv	s2,a0
    800057b2:	c905                	beqz	a0,800057e2 <sys_open+0x13c>
    ilock(ip);
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	f86080e7          	jalr	-122(ra) # 8000373a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057bc:	04491703          	lh	a4,68(s2)
    800057c0:	4785                	li	a5,1
    800057c2:	f4f712e3          	bne	a4,a5,80005706 <sys_open+0x60>
    800057c6:	f4c42783          	lw	a5,-180(s0)
    800057ca:	dba1                	beqz	a5,8000571a <sys_open+0x74>
      iunlockput(ip);
    800057cc:	854a                	mv	a0,s2
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	1ce080e7          	jalr	462(ra) # 8000399c <iunlockput>
      end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	9b6080e7          	jalr	-1610(ra) # 8000418c <end_op>
      return -1;
    800057de:	54fd                	li	s1,-1
    800057e0:	b76d                	j	8000578a <sys_open+0xe4>
      end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	9aa080e7          	jalr	-1622(ra) # 8000418c <end_op>
      return -1;
    800057ea:	54fd                	li	s1,-1
    800057ec:	bf79                	j	8000578a <sys_open+0xe4>
    iunlockput(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	1ac080e7          	jalr	428(ra) # 8000399c <iunlockput>
    end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	994080e7          	jalr	-1644(ra) # 8000418c <end_op>
    return -1;
    80005800:	54fd                	li	s1,-1
    80005802:	b761                	j	8000578a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005804:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005808:	04691783          	lh	a5,70(s2)
    8000580c:	02f99223          	sh	a5,36(s3)
    80005810:	bf2d                	j	8000574a <sys_open+0xa4>
    itrunc(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	034080e7          	jalr	52(ra) # 80003848 <itrunc>
    8000581c:	bfb1                	j	80005778 <sys_open+0xd2>
      fileclose(f);
    8000581e:	854e                	mv	a0,s3
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	db8080e7          	jalr	-584(ra) # 800045d8 <fileclose>
    iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	172080e7          	jalr	370(ra) # 8000399c <iunlockput>
    end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	95a080e7          	jalr	-1702(ra) # 8000418c <end_op>
    return -1;
    8000583a:	54fd                	li	s1,-1
    8000583c:	b7b9                	j	8000578a <sys_open+0xe4>

000000008000583e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000583e:	7175                	addi	sp,sp,-144
    80005840:	e506                	sd	ra,136(sp)
    80005842:	e122                	sd	s0,128(sp)
    80005844:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	8c6080e7          	jalr	-1850(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000584e:	08000613          	li	a2,128
    80005852:	f7040593          	addi	a1,s0,-144
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	366080e7          	jalr	870(ra) # 80002bbe <argstr>
    80005860:	02054963          	bltz	a0,80005892 <sys_mkdir+0x54>
    80005864:	4681                	li	a3,0
    80005866:	4601                	li	a2,0
    80005868:	4585                	li	a1,1
    8000586a:	f7040513          	addi	a0,s0,-144
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	7fe080e7          	jalr	2046(ra) # 8000506c <create>
    80005876:	cd11                	beqz	a0,80005892 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	124080e7          	jalr	292(ra) # 8000399c <iunlockput>
  end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	90c080e7          	jalr	-1780(ra) # 8000418c <end_op>
  return 0;
    80005888:	4501                	li	a0,0
}
    8000588a:	60aa                	ld	ra,136(sp)
    8000588c:	640a                	ld	s0,128(sp)
    8000588e:	6149                	addi	sp,sp,144
    80005890:	8082                	ret
    end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	8fa080e7          	jalr	-1798(ra) # 8000418c <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b7fd                	j	8000588a <sys_mkdir+0x4c>

000000008000589e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000589e:	7135                	addi	sp,sp,-160
    800058a0:	ed06                	sd	ra,152(sp)
    800058a2:	e922                	sd	s0,144(sp)
    800058a4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	866080e7          	jalr	-1946(ra) # 8000410c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ae:	08000613          	li	a2,128
    800058b2:	f7040593          	addi	a1,s0,-144
    800058b6:	4501                	li	a0,0
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	306080e7          	jalr	774(ra) # 80002bbe <argstr>
    800058c0:	04054a63          	bltz	a0,80005914 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058c4:	f6c40593          	addi	a1,s0,-148
    800058c8:	4505                	li	a0,1
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	2b0080e7          	jalr	688(ra) # 80002b7a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058d2:	04054163          	bltz	a0,80005914 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058d6:	f6840593          	addi	a1,s0,-152
    800058da:	4509                	li	a0,2
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	29e080e7          	jalr	670(ra) # 80002b7a <argint>
     argint(1, &major) < 0 ||
    800058e4:	02054863          	bltz	a0,80005914 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058e8:	f6841683          	lh	a3,-152(s0)
    800058ec:	f6c41603          	lh	a2,-148(s0)
    800058f0:	458d                	li	a1,3
    800058f2:	f7040513          	addi	a0,s0,-144
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	776080e7          	jalr	1910(ra) # 8000506c <create>
     argint(2, &minor) < 0 ||
    800058fe:	c919                	beqz	a0,80005914 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	09c080e7          	jalr	156(ra) # 8000399c <iunlockput>
  end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	884080e7          	jalr	-1916(ra) # 8000418c <end_op>
  return 0;
    80005910:	4501                	li	a0,0
    80005912:	a031                	j	8000591e <sys_mknod+0x80>
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	878080e7          	jalr	-1928(ra) # 8000418c <end_op>
    return -1;
    8000591c:	557d                	li	a0,-1
}
    8000591e:	60ea                	ld	ra,152(sp)
    80005920:	644a                	ld	s0,144(sp)
    80005922:	610d                	addi	sp,sp,160
    80005924:	8082                	ret

0000000080005926 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005926:	7135                	addi	sp,sp,-160
    80005928:	ed06                	sd	ra,152(sp)
    8000592a:	e922                	sd	s0,144(sp)
    8000592c:	e526                	sd	s1,136(sp)
    8000592e:	e14a                	sd	s2,128(sp)
    80005930:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005932:	ffffc097          	auipc	ra,0xffffc
    80005936:	07e080e7          	jalr	126(ra) # 800019b0 <myproc>
    8000593a:	892a                	mv	s2,a0
  
  begin_op();
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	7d0080e7          	jalr	2000(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005944:	08000613          	li	a2,128
    80005948:	f6040593          	addi	a1,s0,-160
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	270080e7          	jalr	624(ra) # 80002bbe <argstr>
    80005956:	04054b63          	bltz	a0,800059ac <sys_chdir+0x86>
    8000595a:	f6040513          	addi	a0,s0,-160
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	592080e7          	jalr	1426(ra) # 80003ef0 <namei>
    80005966:	84aa                	mv	s1,a0
    80005968:	c131                	beqz	a0,800059ac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	dd0080e7          	jalr	-560(ra) # 8000373a <ilock>
  if(ip->type != T_DIR){
    80005972:	04449703          	lh	a4,68(s1)
    80005976:	4785                	li	a5,1
    80005978:	04f71063          	bne	a4,a5,800059b8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	e7e080e7          	jalr	-386(ra) # 800037fc <iunlock>
  iput(p->cwd);
    80005986:	15093503          	ld	a0,336(s2)
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	f6a080e7          	jalr	-150(ra) # 800038f4 <iput>
  end_op();
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	7fa080e7          	jalr	2042(ra) # 8000418c <end_op>
  p->cwd = ip;
    8000599a:	14993823          	sd	s1,336(s2)
  return 0;
    8000599e:	4501                	li	a0,0
}
    800059a0:	60ea                	ld	ra,152(sp)
    800059a2:	644a                	ld	s0,144(sp)
    800059a4:	64aa                	ld	s1,136(sp)
    800059a6:	690a                	ld	s2,128(sp)
    800059a8:	610d                	addi	sp,sp,160
    800059aa:	8082                	ret
    end_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	7e0080e7          	jalr	2016(ra) # 8000418c <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	b7ed                	j	800059a0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	fe2080e7          	jalr	-30(ra) # 8000399c <iunlockput>
    end_op();
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	7ca080e7          	jalr	1994(ra) # 8000418c <end_op>
    return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	bfd1                	j	800059a0 <sys_chdir+0x7a>

00000000800059ce <sys_exec>:

uint64
sys_exec(void)
{
    800059ce:	7145                	addi	sp,sp,-464
    800059d0:	e786                	sd	ra,456(sp)
    800059d2:	e3a2                	sd	s0,448(sp)
    800059d4:	ff26                	sd	s1,440(sp)
    800059d6:	fb4a                	sd	s2,432(sp)
    800059d8:	f74e                	sd	s3,424(sp)
    800059da:	f352                	sd	s4,416(sp)
    800059dc:	ef56                	sd	s5,408(sp)
    800059de:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059e0:	08000613          	li	a2,128
    800059e4:	f4040593          	addi	a1,s0,-192
    800059e8:	4501                	li	a0,0
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	1d4080e7          	jalr	468(ra) # 80002bbe <argstr>
    return -1;
    800059f2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059f4:	0c054a63          	bltz	a0,80005ac8 <sys_exec+0xfa>
    800059f8:	e3840593          	addi	a1,s0,-456
    800059fc:	4505                	li	a0,1
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	19e080e7          	jalr	414(ra) # 80002b9c <argaddr>
    80005a06:	0c054163          	bltz	a0,80005ac8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a0a:	10000613          	li	a2,256
    80005a0e:	4581                	li	a1,0
    80005a10:	e4040513          	addi	a0,s0,-448
    80005a14:	ffffb097          	auipc	ra,0xffffb
    80005a18:	2cc080e7          	jalr	716(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a1c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a20:	89a6                	mv	s3,s1
    80005a22:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a24:	02000a13          	li	s4,32
    80005a28:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a2c:	00391513          	slli	a0,s2,0x3
    80005a30:	e3040593          	addi	a1,s0,-464
    80005a34:	e3843783          	ld	a5,-456(s0)
    80005a38:	953e                	add	a0,a0,a5
    80005a3a:	ffffd097          	auipc	ra,0xffffd
    80005a3e:	0a6080e7          	jalr	166(ra) # 80002ae0 <fetchaddr>
    80005a42:	02054a63          	bltz	a0,80005a76 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a46:	e3043783          	ld	a5,-464(s0)
    80005a4a:	c3b9                	beqz	a5,80005a90 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	0a8080e7          	jalr	168(ra) # 80000af4 <kalloc>
    80005a54:	85aa                	mv	a1,a0
    80005a56:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a5a:	cd11                	beqz	a0,80005a76 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a5c:	6605                	lui	a2,0x1
    80005a5e:	e3043503          	ld	a0,-464(s0)
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	0d0080e7          	jalr	208(ra) # 80002b32 <fetchstr>
    80005a6a:	00054663          	bltz	a0,80005a76 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a6e:	0905                	addi	s2,s2,1
    80005a70:	09a1                	addi	s3,s3,8
    80005a72:	fb491be3          	bne	s2,s4,80005a28 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a76:	10048913          	addi	s2,s1,256
    80005a7a:	6088                	ld	a0,0(s1)
    80005a7c:	c529                	beqz	a0,80005ac6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	f7a080e7          	jalr	-134(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a86:	04a1                	addi	s1,s1,8
    80005a88:	ff2499e3          	bne	s1,s2,80005a7a <sys_exec+0xac>
  return -1;
    80005a8c:	597d                	li	s2,-1
    80005a8e:	a82d                	j	80005ac8 <sys_exec+0xfa>
      argv[i] = 0;
    80005a90:	0a8e                	slli	s5,s5,0x3
    80005a92:	fc040793          	addi	a5,s0,-64
    80005a96:	9abe                	add	s5,s5,a5
    80005a98:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a9c:	e4040593          	addi	a1,s0,-448
    80005aa0:	f4040513          	addi	a0,s0,-192
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	194080e7          	jalr	404(ra) # 80004c38 <exec>
    80005aac:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aae:	10048993          	addi	s3,s1,256
    80005ab2:	6088                	ld	a0,0(s1)
    80005ab4:	c911                	beqz	a0,80005ac8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	f42080e7          	jalr	-190(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abe:	04a1                	addi	s1,s1,8
    80005ac0:	ff3499e3          	bne	s1,s3,80005ab2 <sys_exec+0xe4>
    80005ac4:	a011                	j	80005ac8 <sys_exec+0xfa>
  return -1;
    80005ac6:	597d                	li	s2,-1
}
    80005ac8:	854a                	mv	a0,s2
    80005aca:	60be                	ld	ra,456(sp)
    80005acc:	641e                	ld	s0,448(sp)
    80005ace:	74fa                	ld	s1,440(sp)
    80005ad0:	795a                	ld	s2,432(sp)
    80005ad2:	79ba                	ld	s3,424(sp)
    80005ad4:	7a1a                	ld	s4,416(sp)
    80005ad6:	6afa                	ld	s5,408(sp)
    80005ad8:	6179                	addi	sp,sp,464
    80005ada:	8082                	ret

0000000080005adc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005adc:	7139                	addi	sp,sp,-64
    80005ade:	fc06                	sd	ra,56(sp)
    80005ae0:	f822                	sd	s0,48(sp)
    80005ae2:	f426                	sd	s1,40(sp)
    80005ae4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ae6:	ffffc097          	auipc	ra,0xffffc
    80005aea:	eca080e7          	jalr	-310(ra) # 800019b0 <myproc>
    80005aee:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005af0:	fd840593          	addi	a1,s0,-40
    80005af4:	4501                	li	a0,0
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	0a6080e7          	jalr	166(ra) # 80002b9c <argaddr>
    return -1;
    80005afe:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b00:	0e054063          	bltz	a0,80005be0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b04:	fc840593          	addi	a1,s0,-56
    80005b08:	fd040513          	addi	a0,s0,-48
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	dfc080e7          	jalr	-516(ra) # 80004908 <pipealloc>
    return -1;
    80005b14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b16:	0c054563          	bltz	a0,80005be0 <sys_pipe+0x104>
  fd0 = -1;
    80005b1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b1e:	fd043503          	ld	a0,-48(s0)
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	508080e7          	jalr	1288(ra) # 8000502a <fdalloc>
    80005b2a:	fca42223          	sw	a0,-60(s0)
    80005b2e:	08054c63          	bltz	a0,80005bc6 <sys_pipe+0xea>
    80005b32:	fc843503          	ld	a0,-56(s0)
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	4f4080e7          	jalr	1268(ra) # 8000502a <fdalloc>
    80005b3e:	fca42023          	sw	a0,-64(s0)
    80005b42:	06054863          	bltz	a0,80005bb2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b46:	4691                	li	a3,4
    80005b48:	fc440613          	addi	a2,s0,-60
    80005b4c:	fd843583          	ld	a1,-40(s0)
    80005b50:	68a8                	ld	a0,80(s1)
    80005b52:	ffffc097          	auipc	ra,0xffffc
    80005b56:	b20080e7          	jalr	-1248(ra) # 80001672 <copyout>
    80005b5a:	02054063          	bltz	a0,80005b7a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b5e:	4691                	li	a3,4
    80005b60:	fc040613          	addi	a2,s0,-64
    80005b64:	fd843583          	ld	a1,-40(s0)
    80005b68:	0591                	addi	a1,a1,4
    80005b6a:	68a8                	ld	a0,80(s1)
    80005b6c:	ffffc097          	auipc	ra,0xffffc
    80005b70:	b06080e7          	jalr	-1274(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b76:	06055563          	bgez	a0,80005be0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b7a:	fc442783          	lw	a5,-60(s0)
    80005b7e:	07e9                	addi	a5,a5,26
    80005b80:	078e                	slli	a5,a5,0x3
    80005b82:	97a6                	add	a5,a5,s1
    80005b84:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b88:	fc042503          	lw	a0,-64(s0)
    80005b8c:	0569                	addi	a0,a0,26
    80005b8e:	050e                	slli	a0,a0,0x3
    80005b90:	9526                	add	a0,a0,s1
    80005b92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b96:	fd043503          	ld	a0,-48(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	a3e080e7          	jalr	-1474(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005ba2:	fc843503          	ld	a0,-56(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	a32080e7          	jalr	-1486(ra) # 800045d8 <fileclose>
    return -1;
    80005bae:	57fd                	li	a5,-1
    80005bb0:	a805                	j	80005be0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bb2:	fc442783          	lw	a5,-60(s0)
    80005bb6:	0007c863          	bltz	a5,80005bc6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bba:	01a78513          	addi	a0,a5,26
    80005bbe:	050e                	slli	a0,a0,0x3
    80005bc0:	9526                	add	a0,a0,s1
    80005bc2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	a0e080e7          	jalr	-1522(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005bd2:	fc843503          	ld	a0,-56(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	a02080e7          	jalr	-1534(ra) # 800045d8 <fileclose>
    return -1;
    80005bde:	57fd                	li	a5,-1
}
    80005be0:	853e                	mv	a0,a5
    80005be2:	70e2                	ld	ra,56(sp)
    80005be4:	7442                	ld	s0,48(sp)
    80005be6:	74a2                	ld	s1,40(sp)
    80005be8:	6121                	addi	sp,sp,64
    80005bea:	8082                	ret
    80005bec:	0000                	unimp
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	d7dfc0ef          	jal	ra,800029ac <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	6d0c                	ld	a1,24(a0)
    80005c8c:	7110                	ld	a2,32(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	cbc080e7          	jalr	-836(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	953e                	add	a0,a0,a5
    80005cec:	00052023          	sw	zero,0(a0)
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	c84080e7          	jalr	-892(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5179b          	slliw	a5,a0,0xd
    80005d0c:	0c201537          	lui	a0,0xc201
    80005d10:	953e                	add	a0,a0,a5
  return irq;
}
    80005d12:	4148                	lw	a0,4(a0)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	c5c080e7          	jalr	-932(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	06a7c963          	blt	a5,a0,80005dc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d54:	0001d797          	auipc	a5,0x1d
    80005d58:	2ac78793          	addi	a5,a5,684 # 80023000 <disk>
    80005d5c:	00a78733          	add	a4,a5,a0
    80005d60:	6789                	lui	a5,0x2
    80005d62:	97ba                	add	a5,a5,a4
    80005d64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d68:	e7ad                	bnez	a5,80005dd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d6a:	00451793          	slli	a5,a0,0x4
    80005d6e:	0001f717          	auipc	a4,0x1f
    80005d72:	29270713          	addi	a4,a4,658 # 80025000 <disk+0x2000>
    80005d76:	6314                	ld	a3,0(a4)
    80005d78:	96be                	add	a3,a3,a5
    80005d7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d7e:	6314                	ld	a3,0(a4)
    80005d80:	96be                	add	a3,a3,a5
    80005d82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d86:	6314                	ld	a3,0(a4)
    80005d88:	96be                	add	a3,a3,a5
    80005d8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d8e:	6318                	ld	a4,0(a4)
    80005d90:	97ba                	add	a5,a5,a4
    80005d92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d96:	0001d797          	auipc	a5,0x1d
    80005d9a:	26a78793          	addi	a5,a5,618 # 80023000 <disk>
    80005d9e:	97aa                	add	a5,a5,a0
    80005da0:	6509                	lui	a0,0x2
    80005da2:	953e                	add	a0,a0,a5
    80005da4:	4785                	li	a5,1
    80005da6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005daa:	0001f517          	auipc	a0,0x1f
    80005dae:	26e50513          	addi	a0,a0,622 # 80025018 <disk+0x2018>
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	4a6080e7          	jalr	1190(ra) # 80002258 <wakeup>
}
    80005dba:	60a2                	ld	ra,8(sp)
    80005dbc:	6402                	ld	s0,0(sp)
    80005dbe:	0141                	addi	sp,sp,16
    80005dc0:	8082                	ret
    panic("free_desc 1");
    80005dc2:	00003517          	auipc	a0,0x3
    80005dc6:	9b650513          	addi	a0,a0,-1610 # 80008778 <syscalls+0x330>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	9b650513          	addi	a0,a0,-1610 # 80008788 <syscalls+0x340>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080005de2 <virtio_disk_init>:
{
    80005de2:	1101                	addi	sp,sp,-32
    80005de4:	ec06                	sd	ra,24(sp)
    80005de6:	e822                	sd	s0,16(sp)
    80005de8:	e426                	sd	s1,8(sp)
    80005dea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dec:	00003597          	auipc	a1,0x3
    80005df0:	9ac58593          	addi	a1,a1,-1620 # 80008798 <syscalls+0x350>
    80005df4:	0001f517          	auipc	a0,0x1f
    80005df8:	33450513          	addi	a0,a0,820 # 80025128 <disk+0x2128>
    80005dfc:	ffffb097          	auipc	ra,0xffffb
    80005e00:	d58080e7          	jalr	-680(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	4398                	lw	a4,0(a5)
    80005e0a:	2701                	sext.w	a4,a4
    80005e0c:	747277b7          	lui	a5,0x74727
    80005e10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e14:	0ef71163          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	43dc                	lw	a5,4(a5)
    80005e1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e20:	4705                	li	a4,1
    80005e22:	0ce79a63          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e26:	100017b7          	lui	a5,0x10001
    80005e2a:	479c                	lw	a5,8(a5)
    80005e2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2e:	4709                	li	a4,2
    80005e30:	0ce79363          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e34:	100017b7          	lui	a5,0x10001
    80005e38:	47d8                	lw	a4,12(a5)
    80005e3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3c:	554d47b7          	lui	a5,0x554d4
    80005e40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e44:	0af71963          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e48:	100017b7          	lui	a5,0x10001
    80005e4c:	4705                	li	a4,1
    80005e4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e50:	470d                	li	a4,3
    80005e52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e56:	c7ffe737          	lui	a4,0xc7ffe
    80005e5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e60:	2701                	sext.w	a4,a4
    80005e62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e64:	472d                	li	a4,11
    80005e66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e68:	473d                	li	a4,15
    80005e6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e6c:	6705                	lui	a4,0x1
    80005e6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e74:	5bdc                	lw	a5,52(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e78:	c7d9                	beqz	a5,80005f06 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e7a:	471d                	li	a4,7
    80005e7c:	08f77d63          	bgeu	a4,a5,80005f16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e80:	100014b7          	lui	s1,0x10001
    80005e84:	47a1                	li	a5,8
    80005e86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e88:	6609                	lui	a2,0x2
    80005e8a:	4581                	li	a1,0
    80005e8c:	0001d517          	auipc	a0,0x1d
    80005e90:	17450513          	addi	a0,a0,372 # 80023000 <disk>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	e4c080e7          	jalr	-436(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e9c:	0001d717          	auipc	a4,0x1d
    80005ea0:	16470713          	addi	a4,a4,356 # 80023000 <disk>
    80005ea4:	00c75793          	srli	a5,a4,0xc
    80005ea8:	2781                	sext.w	a5,a5
    80005eaa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005eac:	0001f797          	auipc	a5,0x1f
    80005eb0:	15478793          	addi	a5,a5,340 # 80025000 <disk+0x2000>
    80005eb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005eb6:	0001d717          	auipc	a4,0x1d
    80005eba:	1ca70713          	addi	a4,a4,458 # 80023080 <disk+0x80>
    80005ebe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ec0:	0001e717          	auipc	a4,0x1e
    80005ec4:	14070713          	addi	a4,a4,320 # 80024000 <disk+0x1000>
    80005ec8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eca:	4705                	li	a4,1
    80005ecc:	00e78c23          	sb	a4,24(a5)
    80005ed0:	00e78ca3          	sb	a4,25(a5)
    80005ed4:	00e78d23          	sb	a4,26(a5)
    80005ed8:	00e78da3          	sb	a4,27(a5)
    80005edc:	00e78e23          	sb	a4,28(a5)
    80005ee0:	00e78ea3          	sb	a4,29(a5)
    80005ee4:	00e78f23          	sb	a4,30(a5)
    80005ee8:	00e78fa3          	sb	a4,31(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret
    panic("could not find virtio disk");
    80005ef6:	00003517          	auipc	a0,0x3
    80005efa:	8b250513          	addi	a0,a0,-1870 # 800087a8 <syscalls+0x360>
    80005efe:	ffffa097          	auipc	ra,0xffffa
    80005f02:	640080e7          	jalr	1600(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f06:	00003517          	auipc	a0,0x3
    80005f0a:	8c250513          	addi	a0,a0,-1854 # 800087c8 <syscalls+0x380>
    80005f0e:	ffffa097          	auipc	ra,0xffffa
    80005f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f16:	00003517          	auipc	a0,0x3
    80005f1a:	8d250513          	addi	a0,a0,-1838 # 800087e8 <syscalls+0x3a0>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>

0000000080005f26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f26:	7159                	addi	sp,sp,-112
    80005f28:	f486                	sd	ra,104(sp)
    80005f2a:	f0a2                	sd	s0,96(sp)
    80005f2c:	eca6                	sd	s1,88(sp)
    80005f2e:	e8ca                	sd	s2,80(sp)
    80005f30:	e4ce                	sd	s3,72(sp)
    80005f32:	e0d2                	sd	s4,64(sp)
    80005f34:	fc56                	sd	s5,56(sp)
    80005f36:	f85a                	sd	s6,48(sp)
    80005f38:	f45e                	sd	s7,40(sp)
    80005f3a:	f062                	sd	s8,32(sp)
    80005f3c:	ec66                	sd	s9,24(sp)
    80005f3e:	e86a                	sd	s10,16(sp)
    80005f40:	1880                	addi	s0,sp,112
    80005f42:	892a                	mv	s2,a0
    80005f44:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f46:	00c52c83          	lw	s9,12(a0)
    80005f4a:	001c9c9b          	slliw	s9,s9,0x1
    80005f4e:	1c82                	slli	s9,s9,0x20
    80005f50:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f54:	0001f517          	auipc	a0,0x1f
    80005f58:	1d450513          	addi	a0,a0,468 # 80025128 <disk+0x2128>
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	c88080e7          	jalr	-888(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f64:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f66:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f68:	0001db97          	auipc	s7,0x1d
    80005f6c:	098b8b93          	addi	s7,s7,152 # 80023000 <disk>
    80005f70:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f72:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f74:	8a4e                	mv	s4,s3
    80005f76:	a051                	j	80005ffa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f78:	00fb86b3          	add	a3,s7,a5
    80005f7c:	96da                	add	a3,a3,s6
    80005f7e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f82:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f84:	0207c563          	bltz	a5,80005fae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f88:	2485                	addiw	s1,s1,1
    80005f8a:	0711                	addi	a4,a4,4
    80005f8c:	25548063          	beq	s1,s5,800061cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f90:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f92:	0001f697          	auipc	a3,0x1f
    80005f96:	08668693          	addi	a3,a3,134 # 80025018 <disk+0x2018>
    80005f9a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f9c:	0006c583          	lbu	a1,0(a3)
    80005fa0:	fde1                	bnez	a1,80005f78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	0685                	addi	a3,a3,1
    80005fa6:	ff879be3          	bne	a5,s8,80005f9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005faa:	57fd                	li	a5,-1
    80005fac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fae:	02905a63          	blez	s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fb2:	f9042503          	lw	a0,-112(s0)
    80005fb6:	00000097          	auipc	ra,0x0
    80005fba:	d90080e7          	jalr	-624(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fbe:	4785                	li	a5,1
    80005fc0:	0297d163          	bge	a5,s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fc4:	f9442503          	lw	a0,-108(s0)
    80005fc8:	00000097          	auipc	ra,0x0
    80005fcc:	d7e080e7          	jalr	-642(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd0:	4789                	li	a5,2
    80005fd2:	0097d863          	bge	a5,s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd6:	f9842503          	lw	a0,-104(s0)
    80005fda:	00000097          	auipc	ra,0x0
    80005fde:	d6c080e7          	jalr	-660(ra) # 80005d46 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fe2:	0001f597          	auipc	a1,0x1f
    80005fe6:	14658593          	addi	a1,a1,326 # 80025128 <disk+0x2128>
    80005fea:	0001f517          	auipc	a0,0x1f
    80005fee:	02e50513          	addi	a0,a0,46 # 80025018 <disk+0x2018>
    80005ff2:	ffffc097          	auipc	ra,0xffffc
    80005ff6:	0da080e7          	jalr	218(ra) # 800020cc <sleep>
  for(int i = 0; i < 3; i++){
    80005ffa:	f9040713          	addi	a4,s0,-112
    80005ffe:	84ce                	mv	s1,s3
    80006000:	bf41                	j	80005f90 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006002:	20058713          	addi	a4,a1,512
    80006006:	00471693          	slli	a3,a4,0x4
    8000600a:	0001d717          	auipc	a4,0x1d
    8000600e:	ff670713          	addi	a4,a4,-10 # 80023000 <disk>
    80006012:	9736                	add	a4,a4,a3
    80006014:	4685                	li	a3,1
    80006016:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000601a:	20058713          	addi	a4,a1,512
    8000601e:	00471693          	slli	a3,a4,0x4
    80006022:	0001d717          	auipc	a4,0x1d
    80006026:	fde70713          	addi	a4,a4,-34 # 80023000 <disk>
    8000602a:	9736                	add	a4,a4,a3
    8000602c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006030:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006034:	7679                	lui	a2,0xffffe
    80006036:	963e                	add	a2,a2,a5
    80006038:	0001f697          	auipc	a3,0x1f
    8000603c:	fc868693          	addi	a3,a3,-56 # 80025000 <disk+0x2000>
    80006040:	6298                	ld	a4,0(a3)
    80006042:	9732                	add	a4,a4,a2
    80006044:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006046:	6298                	ld	a4,0(a3)
    80006048:	9732                	add	a4,a4,a2
    8000604a:	4541                	li	a0,16
    8000604c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000604e:	6298                	ld	a4,0(a3)
    80006050:	9732                	add	a4,a4,a2
    80006052:	4505                	li	a0,1
    80006054:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006058:	f9442703          	lw	a4,-108(s0)
    8000605c:	6288                	ld	a0,0(a3)
    8000605e:	962a                	add	a2,a2,a0
    80006060:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006064:	0712                	slli	a4,a4,0x4
    80006066:	6290                	ld	a2,0(a3)
    80006068:	963a                	add	a2,a2,a4
    8000606a:	05890513          	addi	a0,s2,88
    8000606e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006070:	6294                	ld	a3,0(a3)
    80006072:	96ba                	add	a3,a3,a4
    80006074:	40000613          	li	a2,1024
    80006078:	c690                	sw	a2,8(a3)
  if(write)
    8000607a:	140d0063          	beqz	s10,800061ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000607e:	0001f697          	auipc	a3,0x1f
    80006082:	f826b683          	ld	a3,-126(a3) # 80025000 <disk+0x2000>
    80006086:	96ba                	add	a3,a3,a4
    80006088:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000608c:	0001d817          	auipc	a6,0x1d
    80006090:	f7480813          	addi	a6,a6,-140 # 80023000 <disk>
    80006094:	0001f517          	auipc	a0,0x1f
    80006098:	f6c50513          	addi	a0,a0,-148 # 80025000 <disk+0x2000>
    8000609c:	6114                	ld	a3,0(a0)
    8000609e:	96ba                	add	a3,a3,a4
    800060a0:	00c6d603          	lhu	a2,12(a3)
    800060a4:	00166613          	ori	a2,a2,1
    800060a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ac:	f9842683          	lw	a3,-104(s0)
    800060b0:	6110                	ld	a2,0(a0)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060b8:	20058613          	addi	a2,a1,512
    800060bc:	0612                	slli	a2,a2,0x4
    800060be:	9642                	add	a2,a2,a6
    800060c0:	577d                	li	a4,-1
    800060c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060c6:	00469713          	slli	a4,a3,0x4
    800060ca:	6114                	ld	a3,0(a0)
    800060cc:	96ba                	add	a3,a3,a4
    800060ce:	03078793          	addi	a5,a5,48
    800060d2:	97c2                	add	a5,a5,a6
    800060d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060d6:	611c                	ld	a5,0(a0)
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	4685                	li	a3,1
    800060dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060de:	611c                	ld	a5,0(a0)
    800060e0:	97ba                	add	a5,a5,a4
    800060e2:	4809                	li	a6,2
    800060e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060e8:	611c                	ld	a5,0(a0)
    800060ea:	973e                	add	a4,a4,a5
    800060ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060f8:	6518                	ld	a4,8(a0)
    800060fa:	00275783          	lhu	a5,2(a4)
    800060fe:	8b9d                	andi	a5,a5,7
    80006100:	0786                	slli	a5,a5,0x1
    80006102:	97ba                	add	a5,a5,a4
    80006104:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006108:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000610c:	6518                	ld	a4,8(a0)
    8000610e:	00275783          	lhu	a5,2(a4)
    80006112:	2785                	addiw	a5,a5,1
    80006114:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006118:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006124:	00492703          	lw	a4,4(s2)
    80006128:	4785                	li	a5,1
    8000612a:	02f71163          	bne	a4,a5,8000614c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000612e:	0001f997          	auipc	s3,0x1f
    80006132:	ffa98993          	addi	s3,s3,-6 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006136:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006138:	85ce                	mv	a1,s3
    8000613a:	854a                	mv	a0,s2
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	f90080e7          	jalr	-112(ra) # 800020cc <sleep>
  while(b->disk == 1) {
    80006144:	00492783          	lw	a5,4(s2)
    80006148:	fe9788e3          	beq	a5,s1,80006138 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000614c:	f9042903          	lw	s2,-112(s0)
    80006150:	20090793          	addi	a5,s2,512
    80006154:	00479713          	slli	a4,a5,0x4
    80006158:	0001d797          	auipc	a5,0x1d
    8000615c:	ea878793          	addi	a5,a5,-344 # 80023000 <disk>
    80006160:	97ba                	add	a5,a5,a4
    80006162:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006166:	0001f997          	auipc	s3,0x1f
    8000616a:	e9a98993          	addi	s3,s3,-358 # 80025000 <disk+0x2000>
    8000616e:	00491713          	slli	a4,s2,0x4
    80006172:	0009b783          	ld	a5,0(s3)
    80006176:	97ba                	add	a5,a5,a4
    80006178:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000617c:	854a                	mv	a0,s2
    8000617e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006182:	00000097          	auipc	ra,0x0
    80006186:	bc4080e7          	jalr	-1084(ra) # 80005d46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000618a:	8885                	andi	s1,s1,1
    8000618c:	f0ed                	bnez	s1,8000616e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000618e:	0001f517          	auipc	a0,0x1f
    80006192:	f9a50513          	addi	a0,a0,-102 # 80025128 <disk+0x2128>
    80006196:	ffffb097          	auipc	ra,0xffffb
    8000619a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
}
    8000619e:	70a6                	ld	ra,104(sp)
    800061a0:	7406                	ld	s0,96(sp)
    800061a2:	64e6                	ld	s1,88(sp)
    800061a4:	6946                	ld	s2,80(sp)
    800061a6:	69a6                	ld	s3,72(sp)
    800061a8:	6a06                	ld	s4,64(sp)
    800061aa:	7ae2                	ld	s5,56(sp)
    800061ac:	7b42                	ld	s6,48(sp)
    800061ae:	7ba2                	ld	s7,40(sp)
    800061b0:	7c02                	ld	s8,32(sp)
    800061b2:	6ce2                	ld	s9,24(sp)
    800061b4:	6d42                	ld	s10,16(sp)
    800061b6:	6165                	addi	sp,sp,112
    800061b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ba:	0001f697          	auipc	a3,0x1f
    800061be:	e466b683          	ld	a3,-442(a3) # 80025000 <disk+0x2000>
    800061c2:	96ba                	add	a3,a3,a4
    800061c4:	4609                	li	a2,2
    800061c6:	00c69623          	sh	a2,12(a3)
    800061ca:	b5c9                	j	8000608c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061cc:	f9042583          	lw	a1,-112(s0)
    800061d0:	20058793          	addi	a5,a1,512
    800061d4:	0792                	slli	a5,a5,0x4
    800061d6:	0001d517          	auipc	a0,0x1d
    800061da:	ed250513          	addi	a0,a0,-302 # 800230a8 <disk+0xa8>
    800061de:	953e                	add	a0,a0,a5
  if(write)
    800061e0:	e20d11e3          	bnez	s10,80006002 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061e4:	20058713          	addi	a4,a1,512
    800061e8:	00471693          	slli	a3,a4,0x4
    800061ec:	0001d717          	auipc	a4,0x1d
    800061f0:	e1470713          	addi	a4,a4,-492 # 80023000 <disk>
    800061f4:	9736                	add	a4,a4,a3
    800061f6:	0a072423          	sw	zero,168(a4)
    800061fa:	b505                	j	8000601a <virtio_disk_rw+0xf4>

00000000800061fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	e04a                	sd	s2,0(sp)
    80006206:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006208:	0001f517          	auipc	a0,0x1f
    8000620c:	f2050513          	addi	a0,a0,-224 # 80025128 <disk+0x2128>
    80006210:	ffffb097          	auipc	ra,0xffffb
    80006214:	9d4080e7          	jalr	-1580(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006218:	10001737          	lui	a4,0x10001
    8000621c:	533c                	lw	a5,96(a4)
    8000621e:	8b8d                	andi	a5,a5,3
    80006220:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006222:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006226:	0001f797          	auipc	a5,0x1f
    8000622a:	dda78793          	addi	a5,a5,-550 # 80025000 <disk+0x2000>
    8000622e:	6b94                	ld	a3,16(a5)
    80006230:	0207d703          	lhu	a4,32(a5)
    80006234:	0026d783          	lhu	a5,2(a3)
    80006238:	06f70163          	beq	a4,a5,8000629a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000623c:	0001d917          	auipc	s2,0x1d
    80006240:	dc490913          	addi	s2,s2,-572 # 80023000 <disk>
    80006244:	0001f497          	auipc	s1,0x1f
    80006248:	dbc48493          	addi	s1,s1,-580 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000624c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006250:	6898                	ld	a4,16(s1)
    80006252:	0204d783          	lhu	a5,32(s1)
    80006256:	8b9d                	andi	a5,a5,7
    80006258:	078e                	slli	a5,a5,0x3
    8000625a:	97ba                	add	a5,a5,a4
    8000625c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000625e:	20078713          	addi	a4,a5,512
    80006262:	0712                	slli	a4,a4,0x4
    80006264:	974a                	add	a4,a4,s2
    80006266:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000626a:	e731                	bnez	a4,800062b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000626c:	20078793          	addi	a5,a5,512
    80006270:	0792                	slli	a5,a5,0x4
    80006272:	97ca                	add	a5,a5,s2
    80006274:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006276:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000627a:	ffffc097          	auipc	ra,0xffffc
    8000627e:	fde080e7          	jalr	-34(ra) # 80002258 <wakeup>

    disk.used_idx += 1;
    80006282:	0204d783          	lhu	a5,32(s1)
    80006286:	2785                	addiw	a5,a5,1
    80006288:	17c2                	slli	a5,a5,0x30
    8000628a:	93c1                	srli	a5,a5,0x30
    8000628c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006290:	6898                	ld	a4,16(s1)
    80006292:	00275703          	lhu	a4,2(a4)
    80006296:	faf71be3          	bne	a4,a5,8000624c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000629a:	0001f517          	auipc	a0,0x1f
    8000629e:	e8e50513          	addi	a0,a0,-370 # 80025128 <disk+0x2128>
    800062a2:	ffffb097          	auipc	ra,0xffffb
    800062a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
}
    800062aa:	60e2                	ld	ra,24(sp)
    800062ac:	6442                	ld	s0,16(sp)
    800062ae:	64a2                	ld	s1,8(sp)
    800062b0:	6902                	ld	s2,0(sp)
    800062b2:	6105                	addi	sp,sp,32
    800062b4:	8082                	ret
      panic("virtio_disk_intr status");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	55250513          	addi	a0,a0,1362 # 80008808 <syscalls+0x3c0>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

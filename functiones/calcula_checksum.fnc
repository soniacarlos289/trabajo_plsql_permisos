create or replace function rrhh.CALCULA_CHECKSUM(V_CADENA IN VARCHAR2) return varchar2 is
  Result varchar2(1);
begin
  select
CHR(
 decode
 (
 mod (
  104
  +
    (DECODE(ascii(SUBSTR(V_CADENA,1,1)),'',32,ascii(SUBSTR(V_CADENA,1,1)))-32   )*1
  +
    (DECODE(ascii(SUBSTR(V_CADENA,2,1)),'',32,ascii(SUBSTR(V_CADENA,2,1)))-32   )*2
  +
    (DECODE(ascii(SUBSTR(V_CADENA,3,1)),'',32,ascii(SUBSTR(V_CADENA,3,1)))-32   )*3
  +
    (DECODE(ascii(SUBSTR(V_CADENA,4,1)),'',32,ascii(SUBSTR(V_CADENA,4,1)))-32   )*4
  +
    (DECODE(ascii(SUBSTR(V_CADENA,5,1)),'',32,ascii(SUBSTR(V_CADENA,5,1)))-32   )*5
  +
    (DECODE(ascii(SUBSTR(V_CADENA,6,1)),'',32,ascii(SUBSTR(V_CADENA,6,1)))-32)*6
  +
    (DECODE(ascii(SUBSTR(V_CADENA,7,1)),'',32,ascii(SUBSTR(V_CADENA,7,1)))-32   )*7
  +
    (DECODE(ascii(SUBSTR(V_CADENA,8,1)),'',32,ascii(SUBSTR(V_CADENA,8,1)))-32   )*8
  +
    (DECODE(ascii(SUBSTR(V_CADENA,9,1)),'',32,ascii(SUBSTR(V_CADENA,9,1)))-32   )*9
  +
    (DECODE(ascii(SUBSTR(V_CADENA,10,1)),'',32,ascii(SUBSTR(V_CADENA,10,1)))-32   )*10
  +
    (DECODE(ascii(SUBSTR(V_CADENA,11,1)),'',32,ascii(SUBSTR(V_CADENA,11,1)))-32   )*11
  +
    (DECODE(ascii(SUBSTR(V_CADENA,12,1)),'',32,ascii(SUBSTR(V_CADENA,12,1)))-32   )*12
  +
    (DECODE(ascii(SUBSTR(V_CADENA,13,1)),'',32,ascii(SUBSTR(V_CADENA,13,1)))-32   )*13
 +
    (DECODE(ascii(SUBSTR(V_CADENA,14,1)),'',32,ascii(SUBSTR(V_CADENA,14,1)))-32   )*14
 +
    (DECODE(ascii(SUBSTR(V_CADENA,15,1)),'',32,ascii(SUBSTR(V_CADENA,15,1)))-32   )*15
 +
    (DECODE(ascii(SUBSTR(V_CADENA,16,1)),'',32,ascii(SUBSTR(V_CADENA,16,1)))-32   )*16
 +
    (DECODE(ascii(SUBSTR(V_CADENA,17,1)),'',32,ascii(SUBSTR(V_CADENA,17,1)))-32   )*17
 +
    (DECODE(ascii(SUBSTR(V_CADENA,18,1)),'',32,ascii(SUBSTR(V_CADENA,18,1)))-32   )*18
 +
    (DECODE(ascii(SUBSTR(V_CADENA,19,1)),'',32,ascii(SUBSTR(V_CADENA,19,1)))-32   )*19
 +
    (DECODE(ascii(SUBSTR(V_CADENA,20,1)),'',32,ascii(SUBSTR(V_CADENA,20,1)))-32   )*20
 +
    (DECODE(ascii(SUBSTR(V_CADENA,21,1)),'',32,ascii(SUBSTR(V_CADENA,21,1)))-32   )*21
 +
    (DECODE(ascii(SUBSTR(V_CADENA,22,1)),'',32,ascii(SUBSTR(V_CADENA,22,1)))-32   )*22
 +
    (DECODE(ascii(SUBSTR(V_CADENA,23,1)),'',32,ascii(SUBSTR(V_CADENA,23,1)))-32   )*23
 +
    (DECODE(ascii(SUBSTR(V_CADENA,24,1)),'',32,ascii(SUBSTR(V_CADENA,24,1)))-32   )*24
 +
    (DECODE(ascii(SUBSTR(V_CADENA,25,1)),'',32,ascii(SUBSTR(V_CADENA,25,1)))-32   )*25
 +
    (DECODE(ascii(SUBSTR(V_CADENA,26,1)),'',32,ascii(SUBSTR(V_CADENA,26,1)))-32   )*26
 +
    (DECODE(ascii(SUBSTR(V_CADENA,27,1)),'',32,ascii(SUBSTR(V_CADENA,27,1)))-32   )*27
 +
    (DECODE(ascii(SUBSTR(V_CADENA,28,1)),'',32,ascii(SUBSTR(V_CADENA,28,1)))-32   )*28
 +
    (DECODE(ascii(SUBSTR(V_CADENA,29,1)),'',32,ascii(SUBSTR(V_CADENA,29,1)))-32   )*29
 +
    (DECODE(ascii(SUBSTR(V_CADENA,30,1)),'',32,ascii(SUBSTR(V_CADENA,30,1)))-32   )*30
 +
    (DECODE(ascii(SUBSTR(V_CADENA,31,1)),'',32,ascii(SUBSTR(V_CADENA,31,1)))-32   )*31
 +
    (DECODE(ascii(SUBSTR(V_CADENA,32,1)),'',32,ascii(SUBSTR(V_CADENA,32,1)))-32   )*32
 +
    (DECODE(ascii(SUBSTR(V_CADENA,33,1)),'',32,ascii(SUBSTR(V_CADENA,33,1)))-32   )*33
 +
    (DECODE(ascii(SUBSTR(V_CADENA,34,1)),'',32,ascii(SUBSTR(V_CADENA,34,1)))-32   )*34
 +
    (DECODE(ascii(SUBSTR(V_CADENA,35,1)),'',32,ascii(SUBSTR(V_CADENA,35,1)))-32   )*35
 +
    (DECODE(ascii(SUBSTR(V_CADENA,36,1)),'',32,ascii(SUBSTR(V_CADENA,36,1)))-32   )*36
 +
    (DECODE(ascii(SUBSTR(V_CADENA,37,1)),'',32,ascii(SUBSTR(V_CADENA,37,1)))-32   )*37
 +
    (DECODE(ascii(SUBSTR(V_CADENA,38,1)),'',32,ascii(SUBSTR(V_CADENA,38,1)))-32   )*38
 +
    (DECODE(ascii(SUBSTR(V_CADENA,39,1)),'',32,ascii(SUBSTR(V_CADENA,39,1)))-32   )*39
   ,103 )
 ,91,161
 ,92,162
 ,93,163
 ,94,164
 ,95,165
 ,96,166
 ,97,167
 ,98,168
 ,99,169
 ,100,170
 ,101,171
 ,102,172
 ,0,174,
 --,0,228, /*--cuando el modulo da 0.*/
 mod (
  104
  +
    (DECODE(ascii(SUBSTR(V_CADENA,1,1)),'',32,ascii(SUBSTR(V_CADENA,1,1)))-32   )*1
  +
    (DECODE(ascii(SUBSTR(V_CADENA,2,1)),'',32,ascii(SUBSTR(V_CADENA,2,1)))-32   )*2
  +
    (DECODE(ascii(SUBSTR(V_CADENA,3,1)),'',32,ascii(SUBSTR(V_CADENA,3,1)))-32   )*3
  +
    (DECODE(ascii(SUBSTR(V_CADENA,4,1)),'',32,ascii(SUBSTR(V_CADENA,4,1)))-32   )*4
  +
    (DECODE(ascii(SUBSTR(V_CADENA,5,1)),'',32,ascii(SUBSTR(V_CADENA,5,1)))-32   )*5
  +
    (DECODE(ascii(SUBSTR(V_CADENA,6,1)),'',32,ascii(SUBSTR(V_CADENA,6,1)))-32)*6
  +
    (DECODE(ascii(SUBSTR(V_CADENA,7,1)),'',32,ascii(SUBSTR(V_CADENA,7,1)))-32   )*7
  +
    (DECODE(ascii(SUBSTR(V_CADENA,8,1)),'',32,ascii(SUBSTR(V_CADENA,8,1)))-32   )*8
  +
    (DECODE(ascii(SUBSTR(V_CADENA,9,1)),'',32,ascii(SUBSTR(V_CADENA,9,1)))-32   )*9
  +
    (DECODE(ascii(SUBSTR(V_CADENA,10,1)),'',32,ascii(SUBSTR(V_CADENA,10,1)))-32   )*10
  +
    (DECODE(ascii(SUBSTR(V_CADENA,11,1)),'',32,ascii(SUBSTR(V_CADENA,11,1)))-32   )*11
  +
    (DECODE(ascii(SUBSTR(V_CADENA,12,1)),'',32,ascii(SUBSTR(V_CADENA,12,1)))-32   )*12
  +
    (DECODE(ascii(SUBSTR(V_CADENA,13,1)),'',32,ascii(SUBSTR(V_CADENA,13,1)))-32   )*13
 +
    (DECODE(ascii(SUBSTR(V_CADENA,14,1)),'',32,ascii(SUBSTR(V_CADENA,14,1)))-32   )*14
 +
    (DECODE(ascii(SUBSTR(V_CADENA,15,1)),'',32,ascii(SUBSTR(V_CADENA,15,1)))-32   )*15
 +
    (DECODE(ascii(SUBSTR(V_CADENA,16,1)),'',32,ascii(SUBSTR(V_CADENA,16,1)))-32   )*16
 +
    (DECODE(ascii(SUBSTR(V_CADENA,17,1)),'',32,ascii(SUBSTR(V_CADENA,17,1)))-32   )*17
 +
    (DECODE(ascii(SUBSTR(V_CADENA,18,1)),'',32,ascii(SUBSTR(V_CADENA,18,1)))-32   )*18
 +
    (DECODE(ascii(SUBSTR(V_CADENA,19,1)),'',32,ascii(SUBSTR(V_CADENA,19,1)))-32   )*19
 +
    (DECODE(ascii(SUBSTR(V_CADENA,20,1)),'',32,ascii(SUBSTR(V_CADENA,20,1)))-32   )*20
 +
    (DECODE(ascii(SUBSTR(V_CADENA,21,1)),'',32,ascii(SUBSTR(V_CADENA,21,1)))-32   )*21
 +
    (DECODE(ascii(SUBSTR(V_CADENA,22,1)),'',32,ascii(SUBSTR(V_CADENA,22,1)))-32   )*22
 +
    (DECODE(ascii(SUBSTR(V_CADENA,23,1)),'',32,ascii(SUBSTR(V_CADENA,23,1)))-32   )*23
 +
    (DECODE(ascii(SUBSTR(V_CADENA,24,1)),'',32,ascii(SUBSTR(V_CADENA,24,1)))-32   )*24
 +
    (DECODE(ascii(SUBSTR(V_CADENA,25,1)),'',32,ascii(SUBSTR(V_CADENA,25,1)))-32   )*25
 +
    (DECODE(ascii(SUBSTR(V_CADENA,26,1)),'',32,ascii(SUBSTR(V_CADENA,26,1)))-32   )*26
 +
    (DECODE(ascii(SUBSTR(V_CADENA,27,1)),'',32,ascii(SUBSTR(V_CADENA,27,1)))-32   )*27
 +
    (DECODE(ascii(SUBSTR(V_CADENA,28,1)),'',32,ascii(SUBSTR(V_CADENA,28,1)))-32   )*28
 +
    (DECODE(ascii(SUBSTR(V_CADENA,29,1)),'',32,ascii(SUBSTR(V_CADENA,29,1)))-32   )*29
 +
    (DECODE(ascii(SUBSTR(V_CADENA,30,1)),'',32,ascii(SUBSTR(V_CADENA,30,1)))-32   )*30
 +
    (DECODE(ascii(SUBSTR(V_CADENA,31,1)),'',32,ascii(SUBSTR(V_CADENA,31,1)))-32   )*31
 +
    (DECODE(ascii(SUBSTR(V_CADENA,32,1)),'',32,ascii(SUBSTR(V_CADENA,32,1)))-32   )*32
 +
    (DECODE(ascii(SUBSTR(V_CADENA,33,1)),'',32,ascii(SUBSTR(V_CADENA,33,1)))-32   )*33
 +
    (DECODE(ascii(SUBSTR(V_CADENA,34,1)),'',32,ascii(SUBSTR(V_CADENA,34,1)))-32   )*34
 +
    (DECODE(ascii(SUBSTR(V_CADENA,35,1)),'',32,ascii(SUBSTR(V_CADENA,35,1)))-32   )*35
 +
    (DECODE(ascii(SUBSTR(V_CADENA,36,1)),'',32,ascii(SUBSTR(V_CADENA,36,1)))-32   )*36
 +
    (DECODE(ascii(SUBSTR(V_CADENA,37,1)),'',32,ascii(SUBSTR(V_CADENA,37,1)))-32   )*37
 +
    (DECODE(ascii(SUBSTR(V_CADENA,38,1)),'',32,ascii(SUBSTR(V_CADENA,38,1)))-32   )*38
 +
    (DECODE(ascii(SUBSTR(V_CADENA,39,1)),'',32,ascii(SUBSTR(V_CADENA,39,1)))-32   )*39
   ,103 ) +32
 )
)
 into Result
 from dual;


  return(Result);
end CALCULA_CHECKSUM;
/


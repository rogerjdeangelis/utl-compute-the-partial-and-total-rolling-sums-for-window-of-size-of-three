SAS Forum: Compute the partial and total rolling sums for a window of size of three

My suggestion is to use R if you plan on further time series analysis.
Also, I think the partial windows may cause problems down the line.

  Multiple Solutions (nine in all)

         0. Brilliant innovative solution by (interplay of two set statements plug lag)
            Keintz, Mark
            mkeintz@wharton.upenn.edu
         1. SAS datastep array (This does the partial sums)
         2. R RollingWindow packages. Does not do partial sums
         3. Ehanced simpler solutions by Paul Dorfman
            Paul Dorfman
            sashole@bellsouth.net
         4. Flexible Minimal keystroke macro solution by
            Bartosz Jablonski
            yabwon@gmail.com
         5. Scalable HASH solution by
            Bartosz Jablonski
            yabwon@gmail.com

         5. Scalable HASH solution by
            Bartosz Jablonski
            yabwon@gmail.com

         6. Calculate rolling sums on large data sets with by grouping.
             macro by
            Fried Egg
            00000a7c04fef931-dmarc-request@listserv.uga.edu

github
https://tinyurl.com/y5ub7x6e
https://github.com/rogerjdeangelis/utl-compute-the-partial-and-total-rolling-sums-for-window-of-size-of-three

How to install RollingWindow
library(devtools)
install_github("andrewuhl/RollingWindow")

SAS Forum
https://communities.sas.com/t5/SAS-Visual-Analytics/Sum-cumulative-with-condition/m-p/559830

Other related time series repos
https://tinyurl.com/yyyxh7fw
https://github.com/rogerjdeangelis?utf8=%E2%9C%93&tab=repositories&q=rolling+in%3Aname&type=&language=
https://tinyurl.com/y6sstnk3
https://github.com/rogerjdeangelis?utf8=%E2%9C%93&tab=repositories&q=moving+in%3Aname&type=&language=

*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.Have;
input date$ number;
cards4;
062018 10
052018 15
042018 20
032018 15
022018 30
012018 10
;;;;
run;quit;


SD1.HAVE total obs=6  | Rolling sum for window=3
                      |
    DATE     NUMBER   | Rolling Sum
                      |
   062018      10     |   45        (10+15+20)
   052018      15     |   50        (15+20+15)
   042018      20     |   65        (20+15+30)
   032018      15     |   55        (15+30+10)
   022018      30     |   40        (30+10)
   012018      10     |   10        (10)

*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;

WORK.WANT total obs=6

   DATE     TOT

  062018     45
  052018     50
  042018     65
  032018     55
  022018     40
  012018     10

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/
;

*********************************************************************************
0. Brilliant innovative solution by (interplay of two set statements plug lag)  *
*********************************************************************************
I realized I've come into this thread late, but I think this does the trick:
Two set statements:     yes  (but one set is conditional, to avoid premature end-of-step)
arrays:                 no
summing statement       yes
lag                     yes
data have ;
  input date $ number ;
  cards ;
062018 10
052018 15
042018 20
032018 15
022018 30
012018 10
run ;

%let wsize=3;
data want;
  if end1=0 then set have (keep=number) end=end1;
  else number=0;
  tot + number + -sum(0,l
ag&wsize(number));
  if _n_>=&wsize;
  set have;
run;


****************************************************
1. SAS datastep array (This does the partial sums) *
****************************************************
data wantPre;
     retain obs 1;
     set sd1.have sd1.have(obs=2 in=pad);
     if pad then number=0;
     array ts{0:2} _temporary_;     * ring array shift left;
     ts{mod(obs-1,3)}=number;       * mod allows only indexes 0,1,2;
     if obs>=3 then do;
         tot=sum(of ts{*});
     end;
     obs+1;
     drop obs number;
run;quit;


data want;
   retain date;
   merge wantPre(firstobs=3 in=shift keep=tot) wantPre(keep=date);
   if shift;
run;quit;

**********************************************************
2. R RollingWindow  packages. Does not do partial sums   *
**********************************************************
%utl_submit_r64('
library(haven);
library(dplyr);
library(data.table);
library(RollingWindow);
library(SASxport);
have<-as.data.table(read_sas("d:/sd1/have.sas7bdat"));
have<c(have,have[1:3,]);
have[,want := RollingSum(NUMBER,window = 3)];
write.xport(have,file="d:/xpt/have.xpt");
');
libname xpt xport "d:/xpt/want.xpt";
data want;
  set xpt.have;
run;quit;
libname xpt clear;
R OUTPUT
WORK.WANT total obs=6
   DATA     NUMBER    WANT
  062018      10        .
  052018      15        .
  042018      20       45
  032018      15       50
  022018      30       65
  012018      10       55
***********************************************
3. Ehanced simpler solutions by Paul Dorfman  *
***********************************************
The standard economical way of addressing the problem of finding sequential
rolling sums in a window with W items is using a simple W-queue: The enqueued
item is added to the rolling sum, and the dequeued item is subtracted from it.
Your problem is no exception; but it has a twist since you want to start the
summation from the Wth item rather than #1. If it started with item #1, the
solution would be most straightforward:
data have ;
  input date $ number ;
  cards ;
062018 10
052018 15
042018 20
032018 15
022018 30
012018 10
run ;
%let W = 3 ;
data want (drop = number) ;
  set have ;
  tot + number - sum (0, lag&w (number)) ;
run ;
However, with your setting, the same process has to run backward:
data want (drop = number) ;
  do p = n to 1 by -1 ;
    set have nobs = n point = p ;
    tot + number - sum (0, lag&w (number)) ;
    output ;
  end ;
  stop ;
run ;
The only negative effect of this approach is that the output data set is now in the reversed order.
It can be addressed in a variety of ways, e.g.:
- Save P and resort by it
- Save the TOT values in an array and, after the file is processed, write the output in
the same step from P=1 to N using POINT=P
- Store (P,TOT) pairs in a hash instead of the array and then do the same as above
- Etc.
Below is yet another variation (memory is assumed to be sufficient for the hash H):
data _null_ ;
  dcl hash h (ordered:"A") ;
  h.definekey ("p") ;
  h.definedata ("date", "tot") ;
  h.definedone () ;
  do p = n to 1 by -1 ;
    set have nobs = n point = p ;
    tot + number - sum (0, lag&w (number)) ;
    h.add() ;
  end ;
  h.output (dataset:"want") ;
  stop ;
run ;
Note that despite all these variations, the basic "+-" method of
computing the rolling sum remains the same.
Best regards
**************************************************
4. Flexible Minimal keystroke macro solution     *
**************************************************
data have;
input date$ number;
cards4;
062018 10
052018 15
042018 20
032018 15
022018 30
012018 10
;;;;
run;quit;
data want;
merge
  have
  have(keep = number rename=(number=number_2) firstobs=2)
  have(keep = number rename=(number=number_3) firstobs=3)
  ;
tot = sum(number, of number_:); drop number_:;
run;
*******************************
5. Scalable HASH solution by  *
*******************************
Scallable solution by
Bartosz Jablonski
yabwon@gmail.com
you are 100% right, w=10000 window would blow up my session,
that's why let me share one more approach.

It uses only 2 set statements and an array, and doesn't
require resorting (thanks to "The Magnificent-Do"!).

all the best
Bart

data have ;
  input date $ number ;
  cards ;
062018 10
052018 15
042018 20
032018 15
022018 30
012018 10
run ;

%let W = 3 ;

data want (drop = nr read loop _i_) ;

  set have; /* the first "have" */
  /* window "ahead" array */
  array window[0:%eval(&W-1)] _temporary_;

  /* in the first obs of the first "have"
     we need to populate all window[*] array */
  if _N_ = 1 then
    do;
      loop = &w; /* loop length for window */
      read + 1;  /* enable reading the second "have" */
    end;
  else loop = 1;  /* loop length for _N_ > 1 (read single element) */

  /* when in the first obs of the first "have":
     populate all window[*] array, and with
     next observations just replace one (replace last one with newest" */
  do _I_ = 1 to loop;
    /* do not read second "have" if we passed the last record */
    if read then
            set have(keep = number rename=(number = nr)) /* the second "have" */
              end = eof
              curobs = curobs
            ;

      /* populate the window[*] array by replacing "last in line"
         modulo() function will do the trick */
      window[ mod(curobs,&w.) ] = nr ;

    /* if last record from the second "have" then: */
    if eof then
      do;
        read = 0;   /* stop reading the second "have" but...  */
        curobs + 1; /* continue populating window[*] array... */
        nr = .;     /* with blanks                            */
      end;
  end;

  tot = sum(of window[*]);
run ;

proc print;
run;



******************************************************************
6. Calculate rolling sums on large data sets with by grouping.   *
******************************************************************


/**
  * The purpose of this macro is to calculate rolling window summation
  * <b>fast</b>.  It is aimed at any users who need to calculate rolling sums
  * on large data sets with by grouping.
  * <p>
  * Implements a queue (fifo) using SAS array and uses APP functions for speed.
  * <p>
  * It is assumed that the ordering of the sequence for the rolling window is
  * in ascending order and that at least one by group exists.  The maximum
  * window size is 4,095.
  * <p>
  * Example usage:
  * <pre>
  * data have;
  *   call streaminit(5);
  *   do id=1 to 1e5;
  *     do seq=0 to 55;
  *       num=rounde(rand('uniform',5,55),5);
  *       output;
  *     end;
  *   end;
  * run;
  * %RollingWindow(3)
  * </pre>
  *
  * @param windowSize integer the size of summarization window
  * @param num string the variable we want to sum
  * @param sum string the variable name we output containing with sum value
  * @param by string by statement syntax for determining groupings
  * @param out string output dataset name
  */
%macro RollingWindow(windowSize, num=num, by=id seq, out=want);
  data &out;
    * Declare temporary array with windowSize number of elements. This array
    * will be used to simulate a queue data structure;
    array w[&windowSize] _temporary_;

    * initialize queue with all 0's;
    call pokelong(
        repeat(put(0,rb8.),&windowSize),
        addrlong(w[1]),
        8*&w
    );

    * Loop over rows for the given by grouping.  Combined with the above is how
    * we prevent by groups from inaccurately including elements in the sums from
    * previous rows/by groups;
    do until(last.id);
      set have;
      by &by;

      * Implementation for FIFO (first-in, first-out).  We pop off the element
      * at the first index and shift all other elements to their index-1;
      call pokelong(
        peekclong(addrlong(w[2]),8*&windowSize-8),
        addrlong(w[1]),
        8*&windowSize-8
      );

      * Assign the current row input value to the end of the queue;
      w[&windowSize] = &num;

      * Calculate the rolling window sum and output;
      &sum = sum(of w[*]);
      output;
    end;
  run;
%mend;





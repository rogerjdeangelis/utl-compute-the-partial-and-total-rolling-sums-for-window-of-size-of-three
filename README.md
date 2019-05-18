# utl-compute-the-partial-and-total-rolling-sums-for-window-of-size-of-three
Compute the partial and total rolling sums for window of size of three
    Compute the partial and total rolling sums for a window of size of three

    My suggestion is to use R if you plan on further time series analysis.
    Also, I think the partial windows may cause problems down the line.

      Two Solutions

             1. SAS datastep array (This does the partial sums)
             2. R RollingWindow packages. Does not do partial sums

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

    ****************************************************
    1. SAS datastep array (This does the partial sums) *
    ****************************************************

    data wantPre;
         retain obs 1;
         set sd1.have sd1.have(obs=2 in=pad);
         if pad then number=0;
         array ts{0:2} _temporary_;   * ring array shift left;
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





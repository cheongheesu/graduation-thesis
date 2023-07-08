
libname mysas 'C:\Users\sport\OneDrive\바탕 화면\졸업논문';

proc import out=mysas.birth
datafile='C:\Users\sport\OneDrive\바탕 화면\졸업논문\월별출생아수.xlsx'
dbms=xlsx replace;
getnames=yes;
run;

proc copy inlib=mysas outlib=work;
run;

data birth1;
  set birth;
  rename var3=birth;
  drop var1 var2;
  run;

proc print data=birth1;
run;


data birth2;
  set birth1;
  date=intnx('month', '1jan00'D, _n_-1);
  format date monyy. ;
  t+1;
run;

proc print data=birth2;
run;


symbol i=join v=none l=1 c=black ;


proc gplot data = birth2 ;
	plot birth * date = 1 / frame ;
run ; 
quit;


data fin_birth;
  set birth2;
logbirth=log(birth);
  run;

  proc print data=fin_birth;
  run;

proc gplot data = fin_birth ;
	plot logbirth * date = 1 / frame ;
run ; 
quit;


proc arima data = fin_birth ;
	identify var = birth stationarity = (adf) ; run ;
	identify var = logbirth stationarity = (adf) ; run ;
	identify var = logbirth(1) stationarity = (adf) ; run ;
	identify var = logbirth(1, 12) stationarity = (adf) ; run ;
run ; quit ; 

/* 최종모형 -> 로그변환, 계절차분 */

proc arima data = fin_birth ;
	identify var = logbirth(1, 12) stationarity = (adf) ; run ;
run ; 
quit;

/* 모형 식별 --> (0,1,1)~ (5,1,6)까지 모두 돌려본 결과 위 5개의 결과로 추려짐 */

*ARIMA(1,1,3)(1,1,2)_12;
proc arima data=fin_birth;
	identify var=logbirth(1, 12) noprint;
	estimate p=(1) (12) q=(3) (24) plot;
	run; quit;

*ARIMA(1,1,4)(1,1,2)_12;
proc arima data=fin_birth;
	identify var=logbirth(1, 12) noprint;
	estimate p=(1) (12) q=(4) (24) plot;
	run; quit;

*ARIMA(3,1,1)(1,1,2)_12;
proc arima data=fin_birth;
	identify var=logbirth(1, 12) noprint;
	estimate p=(3) (12) q=(1) (24) plot;
	run; quit;

*ARIMA(3,1,4)(1,1,2)_12;
proc arima data=fin_birth;
	identify var=logbirth(1, 12) noprint;
	estimate p=(3) (12) q=(4) (24) plot;
	run; quit;

*ARIMA(4,1,1)(1,1,2)_12;
proc arima data=fin_birth;
	identify var=logbirth(1, 12) noprint;
	estimate p=(4) (12) q=(1) (24) plot;
	run; quit;


symbol v = none i = join c = blue l = 1 ;
symbol2 v=none i=join c=red l=1 ;

/** 모형 검진 및 예측 **/

proc arima data=fin_birth;
  identify var=logbirth(1,12) nlag=36 noprint;
  estimate p=(1) (12) q=(4) (24) plot; run;
  forecast lead=12 id=date interval=month out=res;
  run;
  quit;

  proc gplot data=res;
    plot logbirth*date=1 forecast*date=2/ overlay;
	run;
	quit;


/*실제 값 변환 */
data new_birth;
  set res;
  ori_data=exp(logbirth);
  fore=exp(forecast);
  run;

  proc print data=new_birth;
  run;

  proc gplot data=new_birth;
  plot ori_data*date=1 fore*date=2/ overlay;
  run; quit;


/*******************************************************************************************/


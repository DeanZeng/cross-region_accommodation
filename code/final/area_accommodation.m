function out=area_accommodation(in,x0)
%% input data
T           = in.T;                 %% time horizons
TD          = in.TD;
Nunit       = in.Nunit;             %% number of units
Ntie        = in.Ntie;              %% number of tie lines
%%------------------------ initialization ---------------------------------
Pmax        = in.Pmax;              %% unit maximum output
Pmin        = in.Pmin;              %% unit minimum output
Rampup      = in.Rampup;            %% unit ramping up rates
Rampdown    = in.Rampdown;          %% unit ramping down rates
Minup       = in.Minup;             %% unit minimun up time
Mindown     = in.Mindown;           %% unit minimum dowm time
Onoff_t0    = in.Onoff_t0;          %% initial status at t=0
Pthermal_t0 = in.Pthermal_t0;       %% initial output at t=0
On_t0       = in.On_t0;             %% length of time unit g has to be on at the beginning
Off_t0      = in.Off_t0;            %% length of time unit g has to be off at the beginning
Demand      = in.Demand;            %% demand
Windmax     = in.Windmax;           %% theory output of wind power
PVmax       = in.PVmax;             %% theory output of PV
Tieline     = in.Tieline;           %% tie lines
Ftie0       = in.Ftie0;             %% fixed power flow
Etie        = in.Etie;              %% exchage energy each day
TDstart     = in.TDstart;
ReserveUp   = in.ReserveUp;         %% up reserve
ReserveDn   = in.ReserveDn;         %% dowen reserve
Ftie_val    = in.Ftie_val;          %% exchange information of tie line power flow 
lamda       = in.lamda;             %% multiplers
Rho         = in.Rho;               %% coefficient of quadratic term
%% variables
%%--------------------------- wind power & PV -----------------------------
Pwind=sdpvar(T,1,'full');    %% output of wind power 
Ppv  =sdpvar(T,1,'full');    %% output of PV 

%%--------------------------- thermal unit --------------------------------
Pthermal = sdpvar(T,Nunit,'full');   %% output of thermal unit
onoff    = binvar(T,Nunit,'full');   %% on_off status;
startup  = binvar(T,Nunit,'full');   %% start up indicator
shutdown = binvar(T,Nunit,'full');   %% shut down indicator
%%---------------------------- tie lines ----------------------------------
Ftie = sdpvar(T,Ntie,'full');        %% tie-line power flow
%% initial assign
assign(Pwind,x0.Pwind);
assign(Ppv,x0.Ppv);
assign(Pthermal, x0.Pthermal);
assign(onoff, x0.onoff);
assign(startup, x0.startup);
assign(shutdown, x0.shutdown);
assign(Ftie, x0.Ftie);
%% constraints
Constraints=[];

%--------------------- thermal unit constraints ------------------------
% binary variable logic
Constraints=[Constraints,(startup-shutdown==onoff-[Onoff_t0;onoff(1:T-1,:)]):'logical_1'];
Constraints=[Constraints,(startup+shutdown<=ones(T,Nunit)):'logical_2'];
% output limit
for t = 1:T
   Constraints = [Constraints, (onoff(t,:).*Pmin <=...
       Pthermal(t,:) <= onoff(t,:).*Pmax):'output limit'];
end
%     for t = 1:T
%        Constraints{a} = [Constraints{a}, (Pmin{a} <=...
%            Pthermal{a}(t,:) <= Pmax{a}):'output limit'];
%     end
% minimum up/down time
Lini=On_t0+Off_t0;
for t=1:Lini
    Constraints = [Constraints,(onoff(t,:) == Onoff_t0 ):'initial status'];
end
for t = Lini+1:T
    for unit = 1:Nunit
        tt=max(1,t-Minup(unit)+1);
        Constraints = [Constraints, (sum(startup(tt:t,unit))...
            <= onoff(t,unit)):'min_up'];
        tt=max(1,t-Mindown(unit)+1);
        Constraints = [Constraints, (sum(shutdown(tt:t,unit))...
            <= 1-onoff(t,unit)):'min_down'];
    end
end
% ramping up/down limit
Constraints=[Constraints,(-Rampdown <= Pthermal(1,:)-Pthermal_t0...
        <= Rampup):'ramp0'];
for t=2:T
    Constraints=[Constraints,(-Rampdown <= Pthermal(t,:)-Pthermal(t-1,:)...
        <= Rampup):'ramp'];
end

%------------------------------- wind power & PV ----------------------
Constraints=[Constraints,(zeros(T,1) <= Pwind <= Windmax):'wind power output limit'];
Constraints=[Constraints,(zeros(T,1) <= Ppv   <= PVmax):'wind power output limit'];

%------------------------------- Tie-line -----------------------------
for line=1:Ntie
    if Tieline(line,2)==1
        Constraints=[Constraints,(Ftie(:,line)==Ftie0(:,line)):'tie typeI'];
    elseif Tieline(line,2)==2
        for t=1:T
            Constraints=[Constraints,(-Tieline(line,3)<=...
                Ftie(t,line)<=Tieline(line,3)):'tie typeII'];
        end
    elseif Tieline(line,2)==3
        for t=1:T
            Constraints=[Constraints,(-Tieline(line,3)<=...
                Ftie(t,line)<=Tieline(line,3)):'tie typeIII 1'];
        end
        for td=1:TD
           Constraints=[Constraints,(sum(Ftie(TDstart(td):TDstart(td+1),line))...
               ==Etie(td,line)):'tie typeIII 2'];
        end
    end
end
%------------------------------- power balance ------------------------
for t=1:T
    Constraints=[Constraints,(sum(Pthermal(t,:))+Pwind(t)+Ppv(t)...
        ==Demand(t)+sum(Ftie(t,:))):'power balance'];
end
%------------------------------- spinning reserve ---------------------
% for t=1:T
%     Constraints=[Constraints,(sum(onoff(t,:).*Pmax)+Windmax(t)+PVmax(t)...
%         +sum(Tieline(:,3))>=Demand(t)+ReserveUp(t)):'up reserve'];
%     Constraints=[Constraints,(sum(onoff(t,:).*Pmin)-sum(Tieline(:,3))...
%         <=Demand(t)-ReserveDn(t)):'down reserve'];
% end
% for t=1:T
%     Constraints=[Constraints,(sum(onoff(t,:).*Pmax - Pthermal(t,:)) >= ReserveUp(t)):'up reserve'];
%     Constraints=[Constraints,(sum(onoff(t,:).*Pmin - Pthermal(t,:)) <= -ReserveDn(t)):'down reserve'];
% end
%%Objective
minLang=[];
%%Objective
minLang= -sum(Pwind)-sum(Ppv);
    for la=1:Ntie
        minLang = minLang +...
            lamda(:,la)'*(Ftie(:,la)-Ftie_val(:,la))+...
            Rho/2*(Ftie(:,la)-Ftie_val(:,la))'*(Ftie(:,la)-Ftie_val(:,la));                
    end
%%solver
Ops = sdpsettings('solver','gurobi','usex0',1,'verbose',0,'showprogress',0);
Ops.gurobi.MIPGap=0.0002;
%         Ops.gurobi.MIPGapAbs=1.0;
Ops.gurobi.OptimalityTol = 0.0002;
%         Ops.gurobi.FeasRelaxBigM   = 1.0e10;
Ops.gurobi.DisplayInterval = 20;
diag = optimize(Constraints,minLang,Ops); 
% check(Constraints);
if diag.problem ~= 0
    error(yalmiperror(diag.problem));
end
%% read values of variables
%%--------------------------- wind power & PV -----------------------------
Pwind_V=value(Pwind);    %% output of wind power 
Ppv_V  =value(Ppv);      %% output of PV 
%%--------------------------- thermal unit --------------------------------
Pthermal_V= value(Pthermal);
onoff_V=value(onoff);
startup_V  = value(startup);
shutdown_V = value( shutdown);
%%---------------------------- tie lines ----------------------------------
Ftie_V = value( Ftie);
minLang_V=value(minLang);
%% return out
out.Pwind    = Pwind_V;
out.Ppv      = Ppv_V;
out.Pthermal = Pthermal_V;
out.onoff    = onoff_V;
out.startup  = startup_V;             
out.shutdown = shutdown_V;            
out.Ftie     = Ftie_V;
out.minLang = minLang_V;
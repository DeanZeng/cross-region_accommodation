%%area_2 case
%%centralized model
%% input data
A=2;                  %% number of areas
T=5;               %% time horizons
TD=0;               %% number of days
Nunit=[3,3];      %%number of units
Demand=[
    90,90
    110,110
    130,130
    100,100
    120,120];     %% demand of each area
%ReserveUp=ones(T,A);  %% up reserve
%ReserveDn=ones(T,A);  %% down reserve

%%------------------------- unit data -------------------------------------
%Minup=cell(1,A);      %% unit minimun up time
%Mindown=cell(1,A);    %% unit minimum dowm time
Pmax=cell(1,A);       %% unit maximum output
Pmax{1}=[100,100,100];
Pmax{2}=[100,100,100];
Pmin=cell(1,A);       %% unit minimum output
Pmin{1}=[30,40,20];
Pmin{2}=[30,40,20];
Rampup=cell(1,A);     %% unit ramping up rates
Rampup{1}=[30,30,30];
Rampup{2}=[30,30,30];
Rampdown=cell(1,A);   %% unit ramping down rates
Rampdown{1}=[30,30,30];
Rampdown{2}=[30,30,30];
Onoff_t0=cell(1,A);     %% initial status at t=0
Onoff_t0{1}=[0,0,0];
Onoff_t0{2}=[0,0,0];
Pthermal_t0=cell(1,A);         %% initial output at t=0
Pthermal_t0{1}=[0,0,0];
Pthermal_t0{2}=[0,0,0];
On_t0=cell(1,A);        %% length of time unit g has to be on at the beginning
On_t0{1}=[0,0,0];
On_t0{2}=[0,0,0];
Off_t0=cell(1,A);       %% length of time unit g has to be off at the beginning
Off_t0{1}=[0,0,0];
Off_t0{2}=[0,0,0];
%%------------------------- unit data -------------------------------------

%%------------------------- wind power and PV data ------------------------
Windmax=[
    85,0
    75,0
    60,0
    75,0
    85,0];  %% theory output of wind power

PVmax  =zeros(T,A);  %% theory output of PV

%%------------------------- wind power and PV data ------------------------

%%----------------------------- tie-line data -----------------------------
Tieline=cell(1,A);   %% tie lines
Tieline{1}=[2,2,45];
Tieline{2}=[1,2,45];
Ntie=[1,1];     %% number of tie lines
Ftie0=cell(1,A);     %% fixed power flow
Etie =cell(1,A);     %% exchage energy each day
TDstart=ones(1,TD+1);
% for a=1:A
%     Tieline{a}=ones(Ntie(a),3);    %% [connected_area, type, flow_max]
%     Ftie0{a}  =ones(T,Ntie(a));    
%     Etie{a}   =ones(TD,Ntie(a));       
% end
%%----------------------------- tie-line data -----------------------------

%% variables
%%--------------------------- wind power & PV -----------------------------
Pwind=sdpvar(T,A,'full');    %% output of wind power 
Ppv  =sdpvar(T,A,'full');    %% output of PV 

%%--------------------------- thermal unit --------------------------------
Pthermal=cell(1,A);          %% output of thermal unit
onoff=cell(1,A);           %% on_off status;
startup=cell(1,A);              %% start up indicator
shutdown=cell(1,A);            %% shut down indicator
for a=1:A
    Pthermal{a} = sdpvar(T,Nunit(a),'full');
    onoff{a}    = binvar(T,Nunit(a),'full');
    startup{a}  = binvar(T,Nunit(a),'full');
    shutdown{a} = binvar(T,Nunit(a),'full');
end

%%---------------------------- tie lines ----------------------------------
Ftie=cell(1,A);
for a=1:A
    Ftie{a} = sdpvar(T,Ntie(a),'full');
end

%% constraints
Constraints=cell(1,A);
for a=1:A
    %--------------------- thermal unit constraints ------------------------
    % binary variable logic
    Constraints{a}=[Constraints{a},(startup{a}-shutdown{a}==onoff{a}-[Onoff_t0{a};onoff{a}(1:T-1,:)]):'logical_1'];
    Constraints{a}=[Constraints{a},(startup{a}+shutdown{a}<=ones(T,Nunit(a))):'logical_2'];
    % output limit
    for t = 1:T
       Constraints{a} = [Constraints{a}, (onoff{a}(t,:).*Pmin{a} <=...
           Pthermal{a}(t,:) <= onoff{a}(t,:).*Pmax{a}):'output limit'];
    end
    % minimum up/down time
%     Lini=On_t0{a}+Off_t0{a};
%     for t=1:Lini
%         onoff{a}(t,:)=Onoff_t0{a};
%     end
%     for t = Lini+1:T
%         for unit = 1:Nunit(a)
%             tt=max(1,t-Minup{a}(unit)+1);
%             Constraints{a} = [Constraints{a}, (sum(startup{a}(tt:t,unit))...
%                 <= onoff{a}(t,unit)):'min_up'];
%             tt=max(1,t-Mindown{a}(unit)+1);
%             Constraints{a} = [Constraints{a}, (sum(shutdown(tt:t,unit))...
%                 <= 1-onoff{a}(t,unit)):'min_down'];
%         end
%     end
    % ramping up/down limit
    Constraints{a}=[Constraints{a},(-Rampdown{a} <= Pthermal{a}(1,:)-Pthermal_t0{a}...
            <= Rampup{a}):'ramp0'];
    for t=2:T
        Constraints{a}=[Constraints{a},(-Rampdown{a} <= Pthermal{a}(t,:)-Pthermal{a}(t-1,:)...
            <= Rampup{a}):'ramp'];
    end
    
    %------------------------------- wind power & PV ----------------------
    Constraints{a}=[Constraints{a},(zeros(T,1) <= Pwind(:,a) <= Windmax(:,a)):'wind power output limit'];
    Constraints{a}=[Constraints{a},(zeros(T,1) <= Ppv(:,a)   <= PVmax(:,a)):'wind power output limit'];
    
    %------------------------------- Tie-line -----------------------------
    for line=1:Ntie(a)
        if Tieline{a}(line,2)==1
            Constraints{a}=[Constraints{a},(Ftie{a}(:,line)==Ftie0{a}(:,line)):'tie typeI'];
        elseif Tieline{a}(line,2)==2
            for t=1:T
                Constraints{a}=[Constraints{a},(-Tieline{a}(line,3)<=...
                    Ftie{a}(t,line)<=Tieline{a}(line,3)):'tie typeII'];
            end
        elseif Tieline{a}(line,2)==3
            for t=1:T
                Constraints{a}=[Constraints{a},(-Tieline{a}(line,3)<=...
                    Ftie{a}(t,line)<=Tieline{a}(line,3)):'tie typeIII 1'];
            end
            for td=1:TD
               Constraints{a}=[Constraints{a},(sum(Ftie{a}(TDstart(td):TDstart(td+1),line))...
                   ==Etie{a}(td,line)):'tie typeIII 2'];
            end
        end
    end
    %------------------------------- power balance ------------------------
    for t=1:T
        Constraints{a}=[Constraints{a},(sum(Pthermal{a}(t,:))+Pwind(t,a)+Ppv(t,a)...
            ==Demand(t,a)+sum(Ftie{a}(t,:))):'power balance'];
    end
    %------------------------------- spinning reserve ---------------------
%     for t=1:T
%         Constraints{a}=[Constraints{a},(sum(onoff{a}(t,:).*Pmax{a})+Windmax(t,a)+PVmax(t,a)...
%             +sum(Tieline{a}(:,3))>=Demand(t,a)+ReserveUp(t,a)):'up reserve'];
%         Constraints{a}=[Constraints{a},(sum(onoff{a}(t,:).*Pmin{a})-sum(Tieline{a}(:,3))...
%             <=Demand(t,a)-ReserveDn(t,a)):'down reserve'];
%     end
end
%%--------------------------- consensus -----------------------------------
Con_global=[];
for a=1:A
    Con_global =[Con_global,Constraints{a}];
end
for a=1:A
    for b=a+1:A
        for la=1:Ntie(a)
            for lb=1:Ntie(b)
                if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                    Con_global =[Con_global,(Ftie{a}(:,la)+Ftie{b}(:,lb)==0):'consensus'];                
                end
            end
        end
    end
end

%% centrialized mode 
% %%--------------------------- Objective -----------------------------------
% maxObj=sum(sum(Pwind))+sum(sum(Ppv));  
% 
% %%--------------------------- solution ------------------------------------
% options=sdpsettings('solver','gurobi');
% optimize(Con_global,-maxObj,options);

%% decentralized mode
%Global constants and defaults
QUIET    = 0;
MAX_ITER = 20;
ABSTOL   = 1e-4;
RELTOL   = 1e-2;
Rho      = 1;
alpha    = 1;
%%global variable (exchange infromation)
lamda=cell(1,A);
deltLam=cell(1,A);
Ftie_val=cell(1,A);
for a=1:A
    Ftie_val{a} = zeros(T,Ntie(a));
    lamda{a} = zeros(T,Ntie(a));
    deltLam{a}= ones(T,Ntie(a));
end
%ADMM solution
for k =1:MAX_ITER
    %%--------------------------- x-update --------------------------------
    %%Objective
    minLang=cell(1,A);
    for a=1:A
        %%Objective
        minLang{a}= -sum(Pwind(:,a))-sum(Ppv(:,a));
        for b=a+1:A
            for la=1:Ntie(a)
                for lb=1:Ntie(b)
                    if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                        minLang{a} = minLang{a} +...
                            lamda{a}(:,la)'*(Ftie{a}(:,la)+Ftie_val{b}(:,lb))+...
                            Rho/2*(Ftie{a}(:,la)+Ftie_val{b}(:,lb))'*(Ftie{a}(:,la)+Ftie_val{b}(:,lb));                
                    end
                end
            end
        end
        %%solver
        Ops = sdpsettings('solver','gurobi','verbose',0,'usex0',1);
        optimize(Constraints{a},minLang{a},Ops);  
    end
    %%--------------------------- z-update --------------------------------
    for a=1:A
        for b=a+1:A
            for la=1:Ntie(a)
                for lb=1:Ntie(b)
                    if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                        Ftie_val{b}(:,lb)=value(Ftie{b}(:,lb))-value(Ftie{a}(:,la));
                        Ftie_val{a}(:,la)=value(Ftie{a}(:,la))-value(Ftie{b}(:,lb));
                        lamda{a}(:,la) = lamda{a}(:,la)+Rho*(value(Ftie{b}(:,lb))+value(Ftie{a}(:,la)));
                        lamda{b}(:,lb) = lamda{b}(:,lb)+Rho*(value(Ftie{b}(:,lb))+value(Ftie{a}(:,la)));
                        deltLam{a}(:,la)=value(Ftie{b}(:,lb))+value(Ftie{a}(:,la));
                        deltLam{b}(:,lb)=value(Ftie{b}(:,lb))+value(Ftie{a}(:,la));
                    end
                end
            end
        end
    end
    Rnorm(k)=0;
    for a=1:A
       Rnorm(k)= Rnorm(k)*Rnorm(k)+ sum(sum(deltLam{a}.*deltLam{a}));
    end
    Rnorm(k)=sqrt(Rnorm(k));
    if Rnorm(k)<ABSTOL
        break;
    end
end
%% results
stairs(value(Pwind));
legend('wind 1','wind 2');
title('wind power');
figure;
stairs(value(Ppv));
legend('PV 1','PV 2');
title('PV generation');
for a=1:A
    figure;
    stairs(value(Pthermal{a}));
    legend('Unit 1','Unit 2','Unit 3');
    title(['thermal unit --area ' num2str(a)]);
end
for a=1:A
    figure;
    stairs(value(Ftie{a}));
    legend('Tie 1');
    title(['tie line --area ' num2str(a)]);
end





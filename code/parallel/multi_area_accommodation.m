function out=multi_area_accommodation(in)
%% input data
area_in=in.area;
T=in.T;
A=in.A;
TD=in.TD;
%% decentralized mode
%Global constants and defaults
QUIET    = 0;
MAX_ITER = 20;
ABSTOL   = 1e-2;
RELTOL   = 1e-2;
Rho      = 0.1;
alpha    = 1;
%%global variable (exchange infromation)
for a=1:A
    area_in(a).Ftie_val = zeros(T,area_in(a).Ntie);
    area_in(a).lamda    = zeros(T,area_in(a).Ntie);
    deltLam{a}          = ones(T,area_in(a).Ntie);
    resDual{a}          = ones(T,area_in(a).Ntie);
    area_in(a).Rho      = Rho;
end
%ADMM solution
% tic;
for k =1:MAX_ITER
    %%--------------------------- x-update --------------------------------
%     pool=parpool;
    for a=1:A
        area_out(a)=area_accommodation(area_in(a),T);
    end
%     delete(pool);   
    %%--------------------------- z-update --------------------------------
    for a=1:A
        for b=a+1:A
            for la=1:area_in(a).Ntie
                for lb=1:area_in(b).Ntie
                    if (area_in(a).Tieline(la,1)==b)&&(area_in(b).Tieline(lb,1)==a)
                        resDual{a}(:,la)=-Rho*((area_out(a).Ftie(:,la)-area_out(b).Ftie(:,lb))/2-area_in(a).Ftie_val(:,la));
                        resDual{b}(:,lb)=-Rho*((area_out(b).Ftie(:,lb)-area_out(a).Ftie(:,la))/2-area_in(b).Ftie_val(:,lb));
                        
                        in(a).Ftie_val(:,la)=(area_out(a).Ftie(:,la)-area_out(b).Ftie(:,lb))/2;
                        in(b).Ftie_val(:,lb)=(area_out(a).Ftie(:,lb)-area_out(a).Ftie(:,la))/2;                      
                        
                        deltLam{a}(:,la)=Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        deltLam{b}(:,lb)=Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;
                        area_in(a).lamda(:,la) = area_in(a).lamda(:,la)+Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        area_in(b).lamda(:,lb) = area_in(b).lamda(:,lb)+Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;                       
                    end
                end
            end
        end
    end
    resPnorm(k)=0;
    resDnorm(k)=0;
    for a=1:A
       resPnorm(k)= resPnorm(k)*resPnorm(k)+ sum(sum(deltLam{a}.*deltLam{a}));
       resDnorm(k)= resDnorm(k)*resDnorm(k)+ sum(sum(resDual{a}.*resDual{a}));
    end
    resPnorm(k)=sqrt(resPnorm(k));
    resDnorm(k)=sqrt(resDnorm(k));
    if (resPnorm(k)<ABSTOL)&&(resDnorm(k)<ABSTOL)
        break;
    end
%     k
%     toc;
end
%% read values of variables
%%--------------------------- wind power & PV -----------------------------
Pwind_V = zeors(T,A);
Ppv     = zeros(T,A);
for a=1:A
    Pwind_V(:,a)= area_out(a).Pwind;    %% output of wind power 
    Ppv_V(:,a)  = area_out(a).Ppv;      %% output of PV 
end
%%--------------------------- thermal unit --------------------------------
Pthermal_V=cell(1,A);          %% output of thermal unit
onoff_V=cell(1,A);           %% on_off status;
startup_V=cell(1,A);              %% start up indicator
shutdown_V=cell(1,A);            %% shut down indicator
for a=1:A
    Pthermal_V{a} = area_out(a).Pthermal;
    onoff_V{a}    = area_out(a).onoff;
    startup_V{a}  = area_out(a).startup;
    shutdown_V{a} = area_out(a).shutdown;
end

%%---------------------------- tie lines ----------------------------------
Ftie_V=cell(1,A);
for a=1:A
    Ftie_V{a} = area_out(a).Ftie;
end

minLang_V=cell(1,A);
for a=1:A
    minLang_V{a}=area_out(a).minLang;
end
out.Pwind    = Pwind_V;
out.Ppv      = Ppv_V;
out.Pthermal = Pthermal_V;
out.onoff    = onoff_V;
out.startup  = startup_V;             
out.shutdown = shutdown_V;            
out.Ftie     = Ftie_V;
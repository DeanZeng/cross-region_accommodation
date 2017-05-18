function [out,hist]=multi_area_accommodation(in)
%% input data
area_in=in.area;
T=in.T;
A=in.A;
TD=in.TD;
%% decentralized mode
%Global constants and defaults
QUIET    = 0;
MAX_ITER = 100;
ABSTOL   = 1e-2;
RELTOL   = 1e-2;
Rho      = 0.001;
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
    parfor a=1:A
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
                        
                        area_in(a).Ftie_val(:,la)=(area_out(a).Ftie(:,la)-area_out(b).Ftie(:,lb))/2;
                        area_in(b).Ftie_val(:,lb)=(area_out(b).Ftie(:,lb)-area_out(a).Ftie(:,la))/2;                      
                        
                        deltLam{a}(:,la)=Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        deltLam{b}(:,lb)=Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;
                        area_in(a).lamda(:,la) = area_in(a).lamda(:,la)+Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        area_in(b).lamda(:,lb) = area_in(b).lamda(:,lb)+Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;                       
                    end
                end
            end
        end
    end
    Xnorm(k)=0;
    Znorm(k)=0;
    LamdaNorm(k)=0;
    hist.resPnorm(k)=0;
    hist.resDnorm(k)=0;
    for a=1:A
       hist.resPnorm(k) = hist.resPnorm(k)*hist.resPnorm(k)+ sum(sum(deltLam{a}.*deltLam{a}));
       hist.resDnorm(k) = hist.resDnorm(k)*hist.resDnorm(k)+ sum(sum(resDual{a}.*resDual{a}));
       Xnorm(k)         = Xnorm(k)*Xnorm(k)+sum(sum(area_out(a).Ftie.*area_out(a).Ftie));
       Znorm(k)         = Znorm(k)*Znorm(k)+sum(sum(area_in(a).Ftie_val.*area_in(a).Ftie_val));
       LamdaNorm(k)     = LamdaNorm(k)*LamdaNorm(k)+sum(sum(area_in(a).lamda.*area_in(a).lamda));
    end
    hist.resPnorm(k)=sqrt(hist.resPnorm(k));
    hist.resDnorm(k)=sqrt(hist.resDnorm(k));
    hist.eps_pri(k) = sqrt(T)*ABSTOL + RELTOL*max(Xnorm(k), Znorm(k));
    hist.eps_dual(k)= sqrt(T)*ABSTOL + RELTOL*norm(LamdaNorm(k));
    hist.iter=k;
    if (hist.resPnorm(k)<hist.eps_pri(k))&&(hist.resDnorm(k)<hist.eps_dual(k))
        break;
    end
%     k
%     toc;
end
%% read values of variables
out.area=area_out;
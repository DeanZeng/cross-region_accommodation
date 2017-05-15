function [ont0,offt0]= getOnoff_t0(onoff,Minup,Mindown)
[T,N]=size(onoff);
ont0=zeros(1,N);
offt0=zeros(1,N);
on=0;
off=0;
for i=1:N
    for t=0:T-1
        if onoff(T-t)==0
            break;
        elseif on>Minup(i)
                break;
        else
            on=on+1;
        end
    end
    if on==0
        ont0(i) = 0;
    else
        ont0(i)=max(0,Minup(i)-on);
    end
end
for i=1:N
    for t=0:T-1
        if onoff(T-t)==1
            break;
        elseif off>Mindown(i)
                break;
        else
            off=off+1;
        end
    end
    if off==0
        offt0(i)=0;
    else
        offt0(i)=max(0,Mindown(i)-off);
    end
end

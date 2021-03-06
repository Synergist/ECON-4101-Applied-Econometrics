require(R.matlab)
bayesPosterior <- readMat('../BayesPosterior.mat'); IRMposs <- bayesPosterior$IRMposs
IRFelas <- readMat('../IRFelas.mat'); IRFelas <- IRFelas$IRFelas;
findex <- readMat('../findex.mat'); findex <- findex$findex;
U <- readMat('../U.mat'); U <- U$U
BETAnc <- readMat('../BETAnc.mat'); BETAnc <- BETAnc$BETAnc

IdentMat <- matrix(IRFelas[,1,findex], nrow=4)
Uhat <- U
p=24;
t=439; # length(kmData)
K <- nrow(IdentMat)
q <- ncol(IdentMat)

# Compute structural multipliers
A = rbind(BETAnc, cbind(diag(K*(p-1)), diag(x=0, K*(p-1), K)))
J = cbind(diag(K), diag(x=0, K, K*(p-1)))
require(DescTools)
IRF = matrix(J %*% (A %^% 0) %*% t(J) %*% IdentMat, nrow = K^2, ncol = 1)
for (i in 1:(t-p-1)) {
  IRF = cbind(IRF, matrix(J %*% (A %^% i) %*% t(J) %*% IdentMat, nrow = K^2, ncol = 1))
}


# Compute structural shocks Ehat from reduced form shocks Uhat
Ehat = MASS::ginv(IdentMat) %*% Uhat[1:q,];

# Cross-multiply the weights for the effect of a given shock on the real
# oil price (given by the relevant row of IRF) with the structural shock
# in question
yhat1 = diag(x=0,t-p,1);
yhat2 = diag(x=0,t-p,1);
yhat3 = diag(x=0,t-p,1);
yhat4 = diag(x=0,t-p,1);
for (i in 1:(t-p)) {
  yhat1[i,] = IRF[3, 1:i] %*% Ehat[1, i:1]
  yhat2[i,] = IRF[7, 1:i] %*% Ehat[2, i:1]
  yhat3[i,] = IRF[11, 1:i] %*% Ehat[3, i:1]
  yhat4[i,] = IRF[15, 1:i] %*% Ehat[4, i:1]
}

time = seq(from = (1973+2/12+1/12*p), to = 2009+8/12, by = 1/12); # starts at 1975.2

cumshock = yhat1 + yhat2 + yhat3 + yhat4;

require(ggplot2)
require(gridExtra)
df <- data.frame(Years=time, CumEffect=yhat1)
g <- ggplot(mapping=aes(x=time)) + geom_vline(aes(xintercept=1978+9/12)) +
  geom_vline(aes(xintercept=1980+9/12)) +
  geom_vline(aes(xintercept=1985+12/12)) +
  geom_vline(aes(xintercept=1990+7/12)) +
  geom_vline(aes(xintercept=1997+7/12)) +
  geom_vline(aes(xintercept=2002+11/12)) +
  scale_y_continuous(limits = c(-100, 100))
g1 <- g + geom_line(aes(y=yhat1), color='blue') +
  ggtitle('Cumulative Effect of Flow Supply Shock on Real Price of Crude Oil')
g2 <- g + geom_line(aes(y=yhat2), color='blue') +
  ggtitle('Cumulative Effect of Flow Demand Shock on Real Price of Crude Oil')
g3 <- g + geom_line(aes(y=yhat3), color='blue') +
  ggtitle('Cumulative Effect of Speculative Demand Shock on Real Price of Crude Oil')

grid.arrange(grobs=list(g1,g2,g3), nrow=3)

#' @title calcEnvmtlFlow
#' @description This function calculates environmental flow requirements (EFR) for MAgPIE retrieved from LPJmL monthly discharge and water availability
#'
#' @param version Switch between LPJmL4 and LPJmL5
#' @param climatetype Switch between different climate scenarios (default: "CRU_4")
#' @param time Time smoothing: average, spline or raw (default)
#' @param averaging_range only specify if time=="average": number of time steps to average
#' @param dof only specify if time=="spline": degrees of freedom needed for spline
#' @param harmonize_baseline FALSE (default): no harmonization, TRUE: if a baseline is specified here data is harmonized to that baseline (from ref_year on)
#' @param ref_year Reference year for harmonization baseline (just specify when harmonize_baseline=TRUE)
#' @param selectyears Years to be returned
#' @param LFR_val Strictness of environmental flow requirements
#' @param HFR_LFR_less10 High flow requirements (share of total water for cells) with LFR<10percent of total water
#' @param HFR_LFR_10_20 High flow requirements (share of total water for cells) with 10percent < LFR < 20percent of total water
#' @param HFR_LFR_20_30 High flow requirements (share of total water for cells) with 20percent < LFR < 30percent of total water
#' @param HFR_LFR_more30 High flow requirements (share of total water for cells) with LFR>30percent of total water
#' @param seasonality grper (default): EFR in growing period per year; total: EFR throughout the year; monthly: monthly EFRs
#'
#' @import magclass
#' @import madrat
#'
#' @return magpie object in cellular resolution
#' @author Felicitas Beier, Abhijeet Mishra
#'
#' @examples
#' \dontrun{ calcOutput("EnvmtlFlow", aggregate = FALSE) }
#'

calcEnvmtlFlow <- function(selectyears=c(1995,2000),
                           version="LPJmL4", climatetype="CRU_4", time="raw", averaging_range=NULL, dof=NULL,
                           harmonize_baseline=FALSE, ref_year="y2015",
                           LFR_val=0.1,HFR_LFR_less10=0.2,HFR_LFR_10_20=0.15,HFR_LFR_20_30=0.07,HFR_LFR_more30=0.00,
                           seasonality="grper"){

  ############################################################
  # Step 1 Determine monthly discharge low flow requirements #
  #        (LFR_monthly_discharge)                           #
  ############################################################

  ### Monthly Discharge
  monthly_discharge_magpie <- calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="mdischarge", years=years, aggregate=FALSE,
                                         harmonize_baseline=FALSE,
                                         time="raw")
  # Transform to array (faster calculation)
  monthly_discharge_magpie <-  as.array(collapseNames(monthly_discharge_magpie))

  ### Calculate LFR_quant
  ## Note: "LFRs correspond to the 90percent quantile of annual flow (Q90),
  ## i.e. to the discharge that is exceeded in nine out of ten months" (Bonsch et al. 2015)
  ## ->
  # Empty array with magpie object names
  LFR_quant <- array(NA,dim=c(dim(monthly_discharge_magpie)[1],length(years)),dimnames=list(dimnames(monthly_discharge_magpie)[[1]],paste("y",years,sep="")))
  # Quantile calculation: Yearly LFR quantile value
  for(year in years){
    # get the LFR_val quantile for each year for all cells
    LFR_quant[,paste("y",year,sep="")] <- apply(monthly_discharge_magpie[,paste("y",year,sep=""),],MARGIN=c(1),quantile,probs=LFR_val)
  }
  # Time-smooth LFR_quant
  LFR_quant <- toolTimeSpline(LFR_quant, dof=dof)


  # Remove no longer needed objects
  rm(monthly_discharge_magpie)

  ### Discharge (smoothed)
  ## Discharge
  monthly_discharge_magpie <- calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="mdischarge", years=years, aggregate=FALSE,
                                         harmonize_baseline=FALSE,
                                         time=time, dof=dof, average_range=average_range) ################ spline or raw here? (originally: averaging_range)
  # Transform to array (faster calculation)
  monthly_discharge_magpie <- as.array(collapseNames(monthly_discharge_magpie))

  ### Calculate LFR discharge values for each month
  # If LFR_quant < magpie_discharge: take LFR_quant
  # Else: take magpie_discharge
  LFR_monthly_discharge <- monthly_discharge_magpie
  for (month in 1:12) {                                     #### What about year-dimension?
    tmp1 <- as.vector(LFR_quant)
    tmp2 <- as.vector(monthly_discharge_magpie[,,month])
    LFR_monthly_discharge[,,month] <- pmin(tmp1,tmp2)
  }
  # Remove no longer needed objects
  rm(LFR_quant)


  ################################################
  # Step 2 Determine low flow requirements (LFR) #
  #        from available water per month        #
  ################################################
  ### Available water per month
  avl_water_month <- calcOutput("AvlWater", version=version, climatetype=climatetype, years=years, seasonality="monthly",
                                harmonize_baseline=FALSE,
                                time="raw")
  avl_water_month    <- as.array(collapseNames(avl_water_month))

  # Empty array
  LFR <- avl_water_month
  LFR[,,] <- NA

  ### Calculate LFRs
  LFR <- avl_water_month * (LFR_monthly_discharge/monthly_discharge_magpie)

  ###################################################################
  # Step 3 Determie monthly high flow requirements (HFR)            #
  #        based on the ratio between LFR_month and avl_water_month #
  ###################################################################
  ## Note: "For rivers with low Q90 values, high-flow events are important
  ## for river channel maintenance, wetland flooding, and riparian vegetation.
  ## HFRs of 20% of available water are therefore assigned to rivers with a
  ## low fraction of Q90 in total discharge. Rivers with a more stable flow
  ## regime receive a lower HFR." (Bonsch et al. 2015)
  HFR <- LFR
  HFR[,,] <- NA

  HFR[LFR<0.1*avl_water_month]  <- HFR_LFR_less10 * avl_water_month[LFR<0.1*avl_water_month]
  HFR[LFR>=0.1*avl_water_month] <- HFR_LFR_10_20  * avl_water_month[LFR>=0.1*avl_water_month]
  HFR[LFR>=0.2*avl_water_month] <- HFR_LFR_20_30  * avl_water_month[LFR>=0.2*avl_water_month]
  HFR[LFR>=0.3*avl_water_month] <- HFR_LFR_more30 * avl_water_month[LFR>=0.3*avl_water_month]
  HFR[avl_water_month<=0]       <- 0

  EFR <- LFR+HFR

  ###########################################
  ############ RETURN STATEMENTS ############
  ###########################################

  ### EFR per cell per month                     ########## needed? maybe delete... (only for consistency)
  if (seasonality=="monthly") {

    # Check for NAs
    if(any(is.na(EFR))){
      stop("produced NA EFR")
    }
    out=EFR
    description="Environmental flow requirements per cell per month"
  }

  ### Total water available per cell per year
  if (seasonality=="total") {

    # Sum up over all month:
    EFR_total <- dimSums(EFR, dim=3)
    # Reduce EFR to 50% of available water where it exceeds this threshold (according to Smakhtin 2004)
    EFR_total[which(EFR_total/avl_water_total>0.5)] <- 0.5*avl_water_total[which(EFR_total/avl_water_total>0.5)]

    # Check for NAs
    if(any(is.na(EFR_total))){
      stop("produced NA EFR_total")
    }
    out=EFR_total
    description="Total EFR per year"
  }

  ### Water available in growing period per cell per year
  if (seasonality=="grper") {

    # magpie object with days per month with same dimension as EFR
    tmp <- c(31,28,31,30,31,30,31,31,30,31,30,31)
    month_days <- new.magpie(names=dimnames(EFR)[[3]])
    month_days[,,] <- tmp
    month_day_magpie <- as.magpie(EFR)
    month_day_magpie[,,] <- 1
    month_day_magpie <- month_day_magpie * month_days

    # Daily water availability
    EFR_day <- EFR/month_day_magpie

    # Growing days per month
    grow_days <- calcOutput("GrowingPeriod", aggregate=FALSE)[,paste("y",years,sep=""),] ############# DOESN'T WORK!!!!!!! WHY???

    # Available water in growing period
    EFR_grper <- EFR_day*grow_days
    # Available water in growing period per year
    EFR_grper <- dimSums(EFR_grper, dim=3)
    # Reduce EFR to 50% of available water where it exceeds this threshold (according to smakhtin 2004)
    EFR_grper[which(EFR_grper/avl_water_grper>0.5)] <- 0.5*avl_water_grper[which(EFR_grper/avl_water_grper>0.5)]

    # Check for NAs
    if(any(is.na(EFR_grper))){
      stop("produced NA EFR_grper")
    }
    out=EFR_grper
    description="EFR in growing period per year"
  }

  return(list(
    x=out,
    weight=NULL,
    unit="mio. m^3",
    description=description,
    isocountries=FALSE))
}
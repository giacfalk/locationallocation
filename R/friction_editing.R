

bb_area = athens_districts; mode="walk"; res_output = 100; dowscaling_model_type = "lm"


    friction_layer <- malariaAtlas::getRaster(dataset_id = "Accessibility__202001_Global_Walking_Only_Friction_Surface", 
                                              extent = matrix(sf::st_bbox(bb_area), ncol = 2))
    
    friction_layer <- raster::raster(friction_layer)
    friction_layer[is.na(friction_layer)] <- mean(raster::values(friction_layer), 
                                               na.rm = TRUE)
    
    x <- osmdata::opq(bbox = st_bbox(bb_area)) %>% osmdata::add_osm_feature(key = "highway") %>% 
      osmdata::osmdata_sf()
    
    r <- raster::raster(raster::extent(st_transform(bb_area, 
                                                    3395)), res = res_output, crs = st_crs(3395)$proj4string)
    
    streets <- fasterize::fasterize(st_buffer(st_transform(x$osm_lines, 
                                                           3395), res_output), r, background = NA, fun = "sum")
    d = terra::rast(streets)
    
    d <- terra::project(d, y = st_crs(4326)$proj4string)

    terra::values(d) <- ifelse(terra::values(d) < 0, 0, 
                               terra::values(d))
    terra::values(d) <- ifelse(is.na(terra::values(d)), 
                               0, terra::values(d))
    d <- raster::raster(d)
    
    d <- raster::crop(d, friction_layer)
    
    d_2 <- d
    d <- raster::stack(d, d_2)
    names(d) <- paste0("l", 1:raster::nlayers(d))
    
    min_iter <- 2
    max_iter <- 10
    p_train <- 0.5
    
    if(length(unique(raster::values(friction_layer)))==1){
    
    raster::values(friction_layer) <- runif(min = unique(raster::values(friction_layer))*0.9, max=unique(raster::values(friction_layer))*1.1, n = length(raster::values(friction_layer)))
    
    }
    
    res_rf <- dissever::dissever(coarse = friction_layer, 
                                 fine = d, method = dowscaling_model_type, p = p_train, 
                                 min_iter = min_iter, max_iter = max_iter, verbose = T)
    friction_layer <- res_rf$map

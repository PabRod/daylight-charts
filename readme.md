[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4316939.svg)](https://doi.org/10.5281/zenodo.4316939)

# Daylight distribution in the European Union <img src="https://ec.europa.eu/transport/sites/transport/files/st/st_2.png" width="140" align="right" />
Interactive applet showing the daylight distribution in every UE city with a population of 100000 r larger, ignoring twilight effects. Interactive applet available in [Shinyapps][app]

[![time](figs/time.png)][app]

## Static images
If preferred, static images corresponding to different cities can be found in [`figs/<region>`](https://github.com/PabRod/daylight-charts/tree/master/figs).

![static](figs/eu/Amsterdam.png)

The blue lines correspond with the sunrise and sunset in <span style="color: blue;">winter time</span>. The red lines, in <span style="color: red;">summer time</span>. The shaded yellow area corresponds with the <span style="color: gold;">dual clock</span> situation.

# Usage

## In Shinyapps
An interactive version of the code can be found in [Shinyapps][app].

## Locally
1. Clone or download + unzip the code.
2. Open the `.Rproj` file with _RStudio_.
3. Execute `shiny::runApp()` for running the interactive app locally.
4. For plotting static images, use:

```r
source("auxs.R") # May require installing missing packages
plot_static_city("Madrid")
```

# More information
- [How is the end of daylight saving time going to affect me?](https://blog.esciencecenter.nl/how-is-the-end-of-daylight-saving-time-going-to-affect-me-2e6e51f96952)
- [Se acaba el horario de verano: ¿cómo va a afectar a su localidad?](https://theconversation.com/se-acaba-el-horario-de-verano-como-va-a-afectar-a-su-localidad-148112) (in Spanish).

[app]: https://pabrod.shinyapps.io/cambio-de-hora/

# Snippet 8.4

using DataFrames
using DataFramesMeta

using PyCall
using Statistics
using PlotlyJS
using TimeSeries
using Random

@pyimport sklearn.metrics as Metrics
@pyimport sklearn.ensemble as Ensemble

@pyimport sklearn.datasets as Datasets
@pyimport sklearn.metrics as Metrics
@pyimport sklearn.model_selection as ModelSelection

"""
function: Implementation of SFI method
reference: De Prado, M. (2018) Advances In Financial Machine Learning
methodology: page 118 SFI section snippet 8.4
"""
function featureImportanceSFI(
    classifier, # classifier for fit and prediction
    X::DataFrame, # features matrix
    y::DataFrame, # labels vector
    nSplits::Int64; # cross-validation n folds
    scoreSampleWeights::Union{Vector, Nothing}=nothing, # sample weights for score step
    trainSampleWeights::Union{Vector, Nothing}=nothing, # sample weights for train step 
    scoring::String="log_loss" # classification prediction and true values scoring type 
)::DataFrame

    trainSampleWeights = isnothing(trainSampleWeights) ? ones(size(X)[1]) : trainSampleWeights
    scoreSampleWeights = isnothing(scoreSampleWeights) ? ones(size(X)[1]) : scoreSampleWeights

    cvGenerator = ModelSelection.KFold(n_splits=nSplits)

    featureNames = names(X)
    importances = DataFrame([name => [] for name in ["FeatureName", "Mean", "StandardDeviation"]])
    for featureName ∈ featureNames
        
        scores = []
        for (i, (train, test)) ∈ enumerate(cvGenerator.split(X |> Matrix))
    
            train .+= 1 # Python indexing starts at 0
            test .+= 1 # Python indexing starts at 0
    
            X0, y0, sampleWeights0 = X[train, [featureName]], y[train, :], trainSampleWeights[train]
            X1, y1, sampleWeights1 = X[test, [featureName]], y[test, :], scoreSampleWeights[test]
            
            fit = classifier.fit(X0 |> Matrix, y0 |> Matrix |> vec, sample_weight=sampleWeights0)

            if scoring == "log_loss"
                predictionProbability = fit.predict_proba(X1 |> Matrix)
                score_ = -Metrics.log_loss(y1 |> Matrix, predictionProbability, sample_weight=sampleWeights1 ,labels=classifier.classes_)        
            
            elseif scoring == "accuracy"
                prediction = fit.predict(X1 |> Matrix)
                score_ = Metrics.accuracy_score(y1 |> Matrix, prediction, sample_weight=sampleWeights1)
            
            else
                throw("'$scoring' method not defined.")
            end
            append!(scores, score_)
        end

        push!(importances, [featureName, mean(scores), std(scores) * size(scores)[1] ^ -0.5])        
    end

    return importances
end


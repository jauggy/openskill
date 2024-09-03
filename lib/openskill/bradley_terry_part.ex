defmodule Openskill.BradleyTerryPart do
  alias Openskill.{Environment, Util}

  @env %Environment{}
  @twobetasq 2 * @env.beta * @env.beta

  def rate(game, _options \\ []) do
    team_ratings = Util.team_rating(game)
    adjacent_teams = Util.ladder_pairs(team_ratings)

    Enum.map(Enum.zip(team_ratings, adjacent_teams), fn {teami_rating, teami_adjacent} ->
      {teami_mu, teami_sigmasq, teami, ranki} = teami_rating

      {omegai, deltai} =
        teami_adjacent
        |> Enum.filter(fn {_, _, _, rankq} -> ranki != rankq end)
        |> Enum.reduce({0, 0}, fn {teamq_mu, teamq_sigmasq, _, rankq}, {omega, delta} ->
          ciq = Math.sqrt(teami_sigmasq + teamq_sigmasq + @twobetasq)
          piq = 1 / (1 + Math.exp((teamq_mu - teami_mu) / ciq))
          sigsq_to_ciq = teami_sigmasq / ciq
          gamma = Math.sqrt(teami_sigmasq) / ciq

          {
            omega + sigsq_to_ciq * (Util.score(rankq, ranki) - piq),
            delta + gamma * sigsq_to_ciq / ciq * piq * (1 - piq)
          }
        end)

      for {muij, sigmaij} <- teami do
        sigmaijsq = sigmaij * sigmaij

        {
          muij + sigmaijsq / teami_sigmasq * omegai,
          sigmaij * Math.sqrt(max(1 - sigmaijsq / teami_sigmasq * deltai, @env.epsilon))
        }
      end
    end)
  end
end

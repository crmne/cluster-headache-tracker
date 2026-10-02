require "test_helper"

class TranslatedGuidesTest < ActionDispatch::IntegrationTest
  test "faq is served in English at its unprefixed URL" do
    get faq_url

    assert_response :success
    assert_select "h1", text: /Frequently Asked Questions/
    assert_select "a[href='https://github.com/crmne/cluster-headache-tracker/issues']", text: "GitHub"
  end

  test "faq is translated into German" do
    get faq_url(locale: "de")

    assert_response :success
    assert_select "h1", text: /Häufige Fragen/
    assert_select "h2", text: /Über Clusterkopfschmerzen/
    assert_select "a[href='https://github.com/crmne/cluster-headache-tracker/issues']", text: "GitHub"
  end

  test "cluster headache diary is translated into Italian" do
    get cluster_headache_diary_url(locale: "it")

    assert_response :success
    assert_select "h1", text: "Diario gratuito per la cefalea a grappolo"
    assert_select "a[href='/it/cluster-headache-diary-template']"
  end

  test "neurologist page is translated into Spanish" do
    get neurologist_url(locale: "es")

    assert_response :success
    assert_select "h1", text: /Para neurólogos/
    assert_select "strong", text: /clusterheadachetracker\.com/
  end

  test "diary template and neurologist diary are translated" do
    get cluster_headache_diary_template_url(locale: "de")
    assert_select "h1", text: "Vorlage für ein Clusterkopfschmerz-Tagebuch"

    get headache_diary_for_neurologist_url(locale: "es")
    assert_select "h1", text: "Diario de cefalea para la consulta de neurología"
    assert_select "a[href='/es/neurologist']", text: "página para neurólogos"
  end
end

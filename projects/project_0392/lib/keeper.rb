require_relative '../models/ia_act'
require_relative '../models/ia_info'
require_relative '../models/ia_add_info'
require_relative '../models/ia_party'
require_relative '../models/ia_runs'

class Keeper < Hamster::Scraper

  def add_run(status)
    IARuns.connection
    IARuns.insert({status: status})
    IARuns.clear_active_connections!
  end

  def update_run(status)
    IARuns.connection
    IARuns.last.update({status: status})
    IARuns.clear_active_connections!
  end

  def get_run
    IARuns.connection
    run_id = IARuns.last[:id]
    IARuns.clear_active_connections!
    run_id
  end

  def add_info(info, run_id, index)
    md5_hash = Digest::MD5.hexdigest(info.to_s)
    IAInfo.connection
    check = IAInfo.where("case_id = \"#{info[:case_id]}\"").to_a
    if check.blank?
      IAInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      puts "[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
    else
      check = IAInfo.where("case_id = \"#{info[:case_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        IAInfo.where("case_id = \"#{info[:case_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        puts "[#{index}][-] OLD INFO DELETED = 1 IN DATABASE!".red
        IAInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        puts "[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
      else
        puts "[#{index}][-] INFO IS ALREADY IN DATABASE! #{info[:case_id]}".yellow
      end
    end
    IAInfo.clear_active_connections!
  end

  def add_add_info(add_info, run_id)
    md5_hash = Digest::MD5.hexdigest(add_info.to_s)
    IAAddInfo.connection
    check = IAAddInfo.where("case_id = \"#{add_info[:case_id]}\"").to_a
    if check.blank?
      IAAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      puts "   [+] ADD INFO ADD IN DATABASE!".green
    else
      check = IAAddInfo.where("case_id = \"#{add_info[:case_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        IAAddInfo.where("case_id = \"#{add_info[:case_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        puts "   [-] OLD ADD INFO DELETED = 1 IN DATABASE!".red
        IAAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        puts "   [+] ADD INFO ADD IN DATABASE!".green
      else
        puts "   [-] ADD INFO IS ALREADY IN DATABASE!".yellow
      end
    end
    IAAddInfo.clear_active_connections!
  end

  def add_activity(activity, run_id)
    md5_hash = Digest::MD5.hexdigest(activity.to_s)
    IAAct.connection
    check = IAAct.where("md5_hash = \"#{md5_hash}\"").to_a
    if check.blank?
      IAAct.insert(activity.merge({ run_id: run_id, md5_hash: md5_hash }))
      puts "   [+] ACTIVITY ADD IN DATABASE!".green
    else
      puts "   [-] ACTIVITY IS ALREADY IN DATABASE!".yellow
    end
    IAAct.clear_active_connections!
  end

  def add_party(party, run_id)
    md5_hash = Digest::MD5.hexdigest(party.to_s)
    IAParty.connection
    check = IAParty.where("case_id = \"#{party[:case_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\"").to_a
    if check.blank?
      IAParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      puts "   [+] PARTY ADD IN DATABASE!".green
    else
      check = IAParty.where("case_id = \"#{party[:case_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        IAParty.where("case_id = \"#{party[:case_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        puts "   [-] OLD PARTY INFO DELETED = 1 IN DATABASE!".red
        IAParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        puts "   [+] PARTY ADD IN DATABASE!".green
      else
        puts "   [-] PARTY IS ALREADY IN DATABASE!".yellow
      end
    end
    IAParty.clear_active_connections!
  end
end
